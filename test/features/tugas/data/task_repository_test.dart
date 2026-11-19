import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/db/enums.dart';
import 'package:super_app/core/sync/sync_queue_writer.dart';
import 'package:super_app/features/tugas/data/task_repository.dart';

/// Antrean yang selalu gagal, untuk membuktikan transaksi ikut batal.
class _FailingQueue extends SyncQueueWriter {
  _FailingQueue(super.database);

  @override
  Future<void> enqueue({
    required String table,
    required String rowId,
    required SyncOperation operation,
  }) => Future.error(StateError('antrean gagal'));
}

void main() {
  late AppDatabase database;
  late TaskRepository repository;
  late DateTime now;
  late int idCounter;

  TaskRepository buildRepository({SyncQueueWriter? queue}) => TaskRepository(
    database,
    userId: 'user-a',
    queue: queue,
    now: () => now,
    newId: () => 'id-${++idCounter}',
  );

  Future<List<SyncQueueEntry>> queueEntries() => (database.select(
    database.syncQueue,
  )..orderBy([(q) => OrderingTerm(expression: q.id)])).get();

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    database = AppDatabase(NativeDatabase.memory());
    now = DateTime.utc(2026, 11, 6, 7, 35);
    idCounter = 0;
    repository = buildRepository();
  });

  tearDown(() => database.close());

  test('tugas yang disimpan bisa dibaca lagi beserta sub-tugasnya', () async {
    final dueAt = DateTime.utc(2026, 11, 7, 23, 59);
    final id = await repository.addTask(
      title: 'Laporan praktikum',
      courseId: 'course-1',
      notes: 'Bab 1 sampai 3',
      dueAt: dueAt,
      priority: TaskPriority.high,
      subtasks: ['Bab 1', 'Bab 2'],
    );

    final tasks = await repository.watchTasks().first;
    expect(tasks, hasLength(1));
    final task = tasks.single;
    expect(task.id, id);
    expect(task.userId, 'user-a');
    expect(task.title, 'Laporan praktikum');
    expect(task.courseId, 'course-1');
    expect(task.notes, 'Bab 1 sampai 3');
    expect(task.dueAt, dueAt);
    expect(task.priority, TaskPriority.high);
    expect(task.status, TaskStatus.active);
    expect(task.createdAt, now);
    expect(task.deletedAt, isNull);

    final subtasks = await repository.watchSubtasks(id).first;
    expect(subtasks.map((s) => s.title), ['Bab 1', 'Bab 2']);
    expect(subtasks.map((s) => s.position), [0, 1]);

    final queue = await queueEntries();
    expect(queue.map((q) => (q.targetTable, q.operation)), [
      ('tasks', SyncOperation.insert),
      ('subtasks', SyncOperation.insert),
      ('subtasks', SyncOperation.insert),
    ]);
  });

  test('tugas tanpa deadline tampil paling akhir', () async {
    await repository.addTask(title: 'Tanpa deadline');
    await repository.addTask(title: 'Besok', dueAt: DateTime.utc(2026, 11, 7));
    await repository.addTask(
      title: 'Hari ini',
      dueAt: DateTime.utc(2026, 11, 6),
    );

    final titles = (await repository.watchTasks().first).map((t) => t.title);
    expect(titles, ['Hari ini', 'Besok', 'Tanpa deadline']);
  });

  test('ubah tugas mengganti isi dan updated_at', () async {
    final id = await repository.addTask(title: 'Lama');
    now = now.add(const Duration(hours: 1));

    await repository.updateTask(id, title: 'Baru', priority: TaskPriority.low);

    final task = (await repository.getTask(id))!;
    expect(task.title, 'Baru');
    expect(task.priority, TaskPriority.low);
    expect(task.updatedAt, now);
    expect((await queueEntries()).last.operation, SyncOperation.update);
  });

  test('tandai selesai lalu urungkan', () async {
    final id = await repository.addTask(title: 'Kuis');

    await repository.setDone(id, done: true);
    var task = (await repository.getTask(id))!;
    expect(task.status, TaskStatus.done);
    expect(task.completedAt, now);

    await repository.setDone(id, done: false);
    task = (await repository.getTask(id))!;
    expect(task.status, TaskStatus.active);
    expect(task.completedAt, isNull);

    final operations = (await queueEntries()).map((q) => q.operation);
    expect(operations, [
      SyncOperation.insert,
      SyncOperation.update,
      SyncOperation.update,
    ]);
  });

  test('hapus = soft delete; urungkan memunculkannya lagi', () async {
    final id = await repository.addTask(title: 'Dihapus');

    await repository.deleteTask(id);
    expect(await repository.watchTasks().first, isEmpty);
    expect(await repository.getTask(id), isNull);

    // Barisnya masih ada di database, hanya ditandai deleted_at.
    final row = await (database.select(
      database.tasks,
    )..where((t) => t.id.equals(id))).getSingle();
    expect(row.deletedAt, now);

    await repository.restoreTask(id);
    expect((await repository.watchTasks().first).single.id, id);

    final operations = (await queueEntries()).map((q) => q.operation);
    expect(operations, [
      SyncOperation.insert,
      SyncOperation.delete,
      SyncOperation.update,
    ]);
  });

  test('centang sub-tugas tercatat di antrean', () async {
    final id = await repository.addTask(title: 'Tugas', subtasks: ['Bab 1']);
    final subtask = (await repository.watchSubtasks(id).first).single;

    await repository.setSubtaskDone(subtask.id, done: true);

    expect((await repository.watchSubtasks(id).first).single.isDone, isTrue);
    final last = (await queueEntries()).last;
    expect(last.targetTable, 'subtasks');
    expect(last.rowId, subtask.id);
    expect(last.operation, SyncOperation.update);
  });

  test('kalau antrean gagal, tugas tidak ikut tersimpan', () async {
    final failing = buildRepository(queue: _FailingQueue(database));

    await expectLater(
      failing.addTask(title: 'Tidak boleh tersimpan', subtasks: ['A']),
      throwsStateError,
    );

    expect(await database.select(database.tasks).get(), isEmpty);
    expect(await database.select(database.subtasks).get(), isEmpty);
    expect(await queueEntries(), isEmpty);
  });

  test('mengubah tugas yang tidak ada = error, antrean tetap kosong', () async {
    await expectLater(repository.deleteTask('tidak-ada'), throwsStateError);
    expect(await queueEntries(), isEmpty);
  });

  test('simpan edit H01: tugas dan sub-tugas dalam satu kali simpan', () async {
    final id = await repository.addTask(
      title: 'Laporan',
      subtasks: ['A', 'B', 'C'],
    );
    final before = await repository.getSubtasks(id);
    await repository.setSubtaskDone(before[0].id, done: true);

    await repository.saveTaskEdit(
      id,
      title: 'Laporan final',
      priority: TaskPriority.high,
      subtasks: [
        (id: before[0].id, title: 'A'),
        (id: before[1].id, title: 'B2'),
        (id: null, title: 'D'),
      ],
    );

    final task = await repository.getTask(id);
    expect(task!.title, 'Laporan final');
    expect(task.priority, TaskPriority.high);
    final after = await repository.getSubtasks(id);
    expect(after.map((s) => (s.title, s.isDone)), [
      ('A', true),
      ('B2', false),
      ('D', false),
    ]);
    expect(after[0].id, before[0].id);
  });

  test('tugas lewat getTaskItem dan watchTaskItem; dihapus = null', () async {
    final id = await repository.addTask(title: 'Kuis');
    expect((await repository.getTaskItem(id))!.task.title, 'Kuis');
    await repository.deleteTask(id);
    expect(await repository.getTaskItem(id), isNull);
    expect(await repository.watchTaskItem(id).first, isNull);
  });

  test('tugas aktif per mata kuliah (layar 20)', () async {
    await repository.addTask(title: 'Lain', courseId: 'c2');
    final done = await repository.addTask(title: 'Selesai', courseId: 'c1');
    await repository.setDone(done, done: true);
    final deleted = await repository.addTask(title: 'Dihapus', courseId: 'c1');
    await repository.deleteTask(deleted);
    await repository.addTask(
      title: 'Kuis',
      courseId: 'c1',
      dueAt: DateTime(2026, 11, 9),
    );
    await repository.addTask(
      title: 'Laporan',
      courseId: 'c1',
      dueAt: DateTime(2026, 11, 6),
    );

    final items = await repository.watchActiveTasksForCourse('c1').first;
    expect(items.map((i) => i.task.title), ['Laporan', 'Kuis']);
  });
}
