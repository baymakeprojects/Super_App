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

  // Semua bacaan disaring per akun [userId]: database HP bisa saja masih
  // menyimpan data akun lain setelah ganti akun.

  /// Tugas yang belum dihapus: deadline terdekat dulu, tanpa deadline di
  /// akhir.
  Stream<List<Task>> watchTasks() {
    final query = _database.select(_database.tasks)
      ..where((t) => t.userId.equals(userId) & t.deletedAt.isNull())
      ..orderBy([
        (t) => OrderingTerm(expression: t.dueAt, nulls: NullsOrder.last),
        (t) => OrderingTerm(expression: t.createdAt),
      ]);
    return query.watch();
  }

  /// Tugas yang belum dihapus beserta nama mata kuliahnya, untuk daftar
  /// di layar 03 (meta "Mata kuliah · jam"). Urutannya sama dengan
  /// [watchTasks]. Mata kuliah yang sudah dihapus dianggap tidak ada.
  Stream<List<TaskListItem>> watchTaskList() {
    return _taskListQuery().watch().map(_toTaskListItems);
  }

  /// Pencarian judul tugas (layar H04), tanpa membedakan huruf besar/kecil.
  /// Kata kosong = daftar kosong.
  Stream<List<TaskListItem>> searchTasks(String keyword) {
    final text = keyword.trim().toLowerCase();
    if (text.isEmpty) return Stream.value(const []);

    final query = _taskListQuery()
      ..where(_database.tasks.title.lower().contains(text));
    return query.watch().map(_toTaskListItems);
  }

  /// Satu tugas, atau `null` kalau tidak ada atau sudah dihapus.
  Future<Task?> getTask(String id) => _taskQuery(id).getSingleOrNull();

  /// Satu tugas yang terus diperbarui (layar 16 Detail tugas).
  /// `null` kalau tidak ada atau sudah dihapus.
  Stream<Task?> watchTask(String id) => _taskQuery(id).watchSingleOrNull();

  /// Sub-tugas milik [taskId] yang belum dihapus, sesuai urutan.
  Stream<List<Subtask>> watchSubtasks(String taskId) {
    final query = _database.select(_database.subtasks)
      ..where(
        (s) =>
            s.userId.equals(userId) &
            s.taskId.equals(taskId) &
            s.deletedAt.isNull(),
      )
      ..orderBy([(s) => OrderingTerm(expression: s.position)]);
    return query.watch();
  }

  /// Progres sub-tugas, misalnya "2/4 selesai" di layar 16.
  Stream<SubtaskProgress> watchSubtaskProgress(String taskId) {
    return watchSubtasks(taskId).map(
      (subtasks) => (
        done: subtasks.where((s) => s.isDone).length,
        total: subtasks.length,
      ),
    );
  }

  SimpleSelectStatement<$TasksTable, Task> _taskQuery(String id) {
    return _database.select(_database.tasks)..where(
      (t) => t.userId.equals(userId) & t.id.equals(id) & t.deletedAt.isNull(),
    );
  }

  JoinedSelectStatement<HasResultSet, dynamic> _taskListQuery() {
    final tasks = _database.tasks;
    final courses = _database.courses;
    return _database.select(tasks).join([
        leftOuterJoin(
          courses,
          courses.id.equalsExp(tasks.courseId) & courses.deletedAt.isNull(),
        ),
      ])
      ..where(tasks.userId.equals(userId) & tasks.deletedAt.isNull())
      ..orderBy([
        OrderingTerm(expression: tasks.dueAt, nulls: NullsOrder.last),
        OrderingTerm(expression: tasks.createdAt),
      ]);
  }

  List<TaskListItem> _toTaskListItems(List<TypedResult> rows) => [
    for (final row in rows)
      TaskListItem(
        task: row.readTable(_database.tasks),
        courseName: row.readTableOrNull(_database.courses)?.name,
      ),
  ];

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

  /// Menambah satu sub-tugas di urutan paling akhir (H01 › + Tambah
  /// sub-tugas). Mengembalikan id sub-tugas baru.
  Future<String> addSubtask(String taskId, String title) {
    return _database.transaction(() async {
      if (await getTask(taskId) == null) {
        throw StateError('Tugas $taskId tidak ditemukan');
      }

      final subtasks = _database.subtasks;
      final maxPosition = subtasks.position.max();
      final last =
          await (_database.selectOnly(subtasks)
                ..addColumns([maxPosition])
                ..where(
                  subtasks.userId.equals(userId) &
                      subtasks.taskId.equals(taskId) &
                      subtasks.deletedAt.isNull(),
                ))
              .map((row) => row.read(maxPosition))
              .getSingle();

      final id = _newId();
      final now = _now();
      await _database
          .into(subtasks)
          .insert(
            SubtasksCompanion.insert(
              id: id,
              userId: userId,
              taskId: taskId,
              title: title,
              position: Value(last == null ? 0 : last + 1),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      await _queue.enqueue(
        table: _subtasksTable,
        rowId: id,
        operation: SyncOperation.insert,
      );
      return id;
    });
  }

  /// Mengganti judul sub-tugas.
  Future<void> renameSubtask(String id, String title) {
    return _writeSubtask(
      id,
      SubtasksCompanion(title: Value(title)),
      SyncOperation.update,
    );
  }

  /// Mencentang atau melepas centang sub-tugas.
  Future<void> setSubtaskDone(String id, {required bool done}) {
    return _writeSubtask(
      id,
      SubtasksCompanion(isDone: Value(done)),
      SyncOperation.update,
    );
  }

  /// Menghapus sub-tugas (soft delete).
  Future<void> deleteSubtask(String id) {
    return _writeSubtask(
      id,
      SubtasksCompanion(deletedAt: Value(_now())),
      SyncOperation.delete,
    );
  }

  /// Urungkan hapus sub-tugas.
  Future<void> restoreSubtask(String id) {
    return _writeSubtask(
      id,
      const SubtasksCompanion(deletedAt: Value(null)),
      SyncOperation.update,
    );
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
                ..where((t) => t.userId.equals(userId) & t.id.equals(id)))
              .write(changes.copyWith(updatedAt: Value(_now())));
      if (changed == 0) throw StateError('Tugas $id tidak ditemukan');
      await _queue.enqueue(table: _tasksTable, rowId: id, operation: operation);
    });
  }

  /// Menulis perubahan satu sub-tugas + antreannya dalam satu transaksi.
  Future<void> _writeSubtask(
    String id,
    SubtasksCompanion changes,
    SyncOperation operation,
  ) {
    return _database.transaction(() async {
      final changed =
          await (_database.update(_database.subtasks)
                ..where((s) => s.userId.equals(userId) & s.id.equals(id)))
              .write(changes.copyWith(updatedAt: Value(_now())));
      if (changed == 0) throw StateError('Sub-tugas $id tidak ditemukan');
      await _queue.enqueue(
        table: _subtasksTable,
        rowId: id,
        operation: operation,
      );
    });
  }
}

/// Satu baris daftar tugas: tugasnya dan nama mata kuliah (kalau ada).
class TaskListItem {
  const TaskListItem({required this.task, required this.courseName});

  final Task task;

  /// `null` = tugas tanpa mata kuliah, atau mata kuliahnya sudah dihapus.
  final String? courseName;
}

/// Progres sub-tugas: berapa yang selesai dari total.
typedef SubtaskProgress = ({int done, int total});
