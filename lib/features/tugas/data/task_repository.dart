import 'package:drift/drift.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/db/enums.dart';
import 'package:super_app/core/sync/sync_queue_writer.dart';
import 'package:super_app/core/utils/uuid.dart';

/// Repository tugas dan sub-tugas. Contoh pola repository Super App:
///
/// - **Baca** dari drift sebagai stream, selalu menyaring `deleted_at is null`.
/// - **Tulis** ke drift dan ke `sync_queue` dalam satu transaksi.
/// - **Hapus** = isi `deleted_at` (soft delete).
/// - **Urungkan** = operasi biasa yang mengembalikan nilai sebelumnya
///   (ikut masuk antrean, supaya perangkat lain juga tahu).
///
/// Layar tidak memanggil drift atau Supabase langsung; selalu lewat sini.
class TaskRepository {
  TaskRepository(
    this._database, {
    required this.userId,
    SyncQueueWriter? queue,
    DateTime Function()? now,
    String Function()? newId,
  }) : _queue = queue ?? SyncQueueWriter(_database, now: now),
       _now = now ?? DateTime.now,
       _newId = newId ?? newUuidV4;

  final AppDatabase _database;
  final SyncQueueWriter _queue;
  final DateTime Function() _now;
  final String Function() _newId;

  /// Pemilik data (akun yang sedang login).
  final String userId;

  static const String _tasksTable = 'tasks';
  static const String _subtasksTable = 'subtasks';

  // ---------------------------------------------------------------------------
  // Baca
  // ---------------------------------------------------------------------------

  /// Tugas yang belum dihapus: deadline terdekat dulu, tanpa deadline di
  /// akhir.
  Stream<List<Task>> watchTasks() {
    final query = _database.select(_database.tasks)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.dueAt, nulls: NullsOrder.last),
        (t) => OrderingTerm(expression: t.createdAt),
      ]);
    return query.watch();
  }

  /// Satu tugas, atau `null` kalau tidak ada atau sudah dihapus.
  Future<Task?> getTask(String id) {
    final query = _database.select(_database.tasks)
      ..where((t) => t.id.equals(id) & t.deletedAt.isNull());
    return query.getSingleOrNull();
  }

  /// Sub-tugas milik [taskId] yang belum dihapus, sesuai urutan.
  Stream<List<Subtask>> watchSubtasks(String taskId) {
    final query = _database.select(_database.subtasks)
      ..where((s) => s.taskId.equals(taskId) & s.deletedAt.isNull())
      ..orderBy([(s) => OrderingTerm(expression: s.position)]);
    return query.watch();
  }

  // ---------------------------------------------------------------------------
  // Tulis
  // ---------------------------------------------------------------------------

  /// Menambah tugas beserta sub-tugasnya. Mengembalikan id tugas baru.
  Future<String> addTask({
    required String title,
    String? courseId,
    String? notes,
    DateTime? dueAt,
    TaskPriority? priority,
    List<String> subtasks = const [],
  }) {
    return _database.transaction(() async {
      final id = _newId();
      final now = _now();

      await _database
          .into(_database.tasks)
          .insert(
            TasksCompanion.insert(
              id: id,
              userId: userId,
              title: title,
              courseId: Value(courseId),
              notes: Value(notes),
              dueAt: Value(dueAt),
              priority: Value(priority),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      await _queue.enqueue(
        table: _tasksTable,
        rowId: id,
        operation: SyncOperation.insert,
      );

      for (var i = 0; i < subtasks.length; i++) {
        final subtaskId = _newId();
        await _database
            .into(_database.subtasks)
            .insert(
              SubtasksCompanion.insert(
                id: subtaskId,
                userId: userId,
                taskId: id,
                title: subtasks[i],
                position: Value(i),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
        await _queue.enqueue(
          table: _subtasksTable,
          rowId: subtaskId,
          operation: SyncOperation.insert,
        );
      }
      return id;
    });
  }

  /// Mengubah isi tugas (judul, catatan, deadline, prioritas, mata kuliah).
  Future<void> updateTask(
    String id, {
    required String title,
    String? courseId,
    String? notes,
    DateTime? dueAt,
    TaskPriority? priority,
  }) {
    return _writeTask(
      id,
      TasksCompanion(
        title: Value(title),
        courseId: Value(courseId),
        notes: Value(notes),
        dueAt: Value(dueAt),
        priority: Value(priority),
      ),
      SyncOperation.update,
    );
  }

  /// Menandai tugas selesai atau belum. Urungkan = panggil lagi dengan
  /// nilai sebaliknya.
  Future<void> setDone(String id, {required bool done}) {
    return _writeTask(
      id,
      TasksCompanion(
        status: Value(done ? TaskStatus.done : TaskStatus.active),
        completedAt: Value(done ? _now() : null),
      ),
      SyncOperation.update,
    );
  }

  /// Menghapus tugas (soft delete: mengisi `deleted_at`).
  Future<void> deleteTask(String id) {
    return _writeTask(
      id,
      TasksCompanion(deletedAt: Value(_now())),
      SyncOperation.delete,
    );
  }

  /// Urungkan hapus: mengosongkan `deleted_at` lagi.
  Future<void> restoreTask(String id) {
    return _writeTask(
      id,
      const TasksCompanion(deletedAt: Value(null)),
      SyncOperation.update,
    );
  }

  /// Mencentang atau melepas centang sub-tugas.
  Future<void> setSubtaskDone(String id, {required bool done}) {
    return _database.transaction(() async {
      final changed =
          await (_database.update(
            _database.subtasks,
          )..where((s) => s.id.equals(id))).write(
            SubtasksCompanion(isDone: Value(done), updatedAt: Value(_now())),
          );
      if (changed == 0) throw StateError('Sub-tugas $id tidak ditemukan');
      await _queue.enqueue(
        table: _subtasksTable,
        rowId: id,
        operation: SyncOperation.update,
      );
    });
  }

  /// Menulis perubahan satu tugas + antreannya dalam satu transaksi.
  Future<void> _writeTask(
    String id,
    TasksCompanion changes,
    SyncOperation operation,
  ) {
    return _database.transaction(() async {
      final changed =
          await (_database.update(_database.tasks)
                ..where((t) => t.id.equals(id)))
              .write(changes.copyWith(updatedAt: Value(_now())));
      if (changed == 0) throw StateError('Tugas $id tidak ditemukan');
      await _queue.enqueue(table: _tasksTable, rowId: id, operation: operation);
    });
  }
}
