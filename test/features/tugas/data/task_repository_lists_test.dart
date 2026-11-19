import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/db/database_provider.dart';
import 'package:super_app/core/db/enums.dart';
import 'package:super_app/features/auth/application/current_user_id_provider.dart';
import 'package:super_app/features/tugas/data/task_repository.dart';
import 'package:super_app/features/tugas/data/task_repository_provider.dart';

void main() {
  late AppDatabase database;
  late TaskRepository repository;
  late DateTime now;
  late int idCounter;

  TaskRepository repoFor(String userId) => TaskRepository(
    database,
    userId: userId,
    now: () => now,
    newId: () => 'id-${++idCounter}',
  );

  Future<void> addCourse(
    String id,
    String name, {
    String userId = 'user-a',
    DateTime? deletedAt,
  }) {
    return database
        .into(database.courses)
        .insert(
          CoursesCompanion.insert(
            id: id,
            userId: userId,
            semesterId: 'semester-1',
            name: name,
            deletedAt: Value(deletedAt),
          ),
        );
  }

  Future<List<SyncQueueEntry>> queueEntries() => (database.select(
    database.syncQueue,
  )..orderBy([(q) => OrderingTerm(expression: q.id)])).get();

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    database = AppDatabase(NativeDatabase.memory());
    now = DateTime.utc(2026, 11, 6, 7, 35);
    idCounter = 0;
    repository = repoFor('user-a');
  });

  tearDown(() => database.close());

  group('daftar tugas (layar 03)', () {
    test('menyertakan nama mata kuliah lewat join', () async {
      await addCourse('course-1', 'Pemrograman Mobile');
      await repository.addTask(title: 'Laporan', courseId: 'course-1');
      await repository.addTask(title: 'Tanpa mata kuliah');

      final items = await repository.watchTaskList().first;
      final byTitle = {for (final i in items) i.task.title: i.courseName};
      expect(byTitle, {
        'Laporan': 'Pemrograman Mobile',
        'Tanpa mata kuliah': null,
      });
    });

    test('mata kuliah yang dihapus tidak ditampilkan namanya', () async {
      await addCourse('course-1', 'Dihapus', deletedAt: now);
      await repository.addTask(title: 'Laporan', courseId: 'course-1');

      final item = (await repository.watchTaskList().first).single;
      expect(item.courseName, isNull);
    });

    test('daftar ikut berubah saat tugas ditambah', () async {
      final updates = repository.watchTaskList();
      final expectation = expectLater(
        updates.map((items) => items.length),
        emitsInOrder([0, 1]),
      );
      await Future<void>.delayed(Duration.zero);
      await repository.addTask(title: 'Baru');
      await expectation;
    });

    test('hanya tugas akun sendiri', () async {
      await repoFor('user-b').addTask(title: 'Milik B');
      await repository.addTask(title: 'Milik A');

      final titles = (await repository.watchTaskList().first).map(
        (i) => i.task.title,
      );
      expect(titles, ['Milik A']);
      expect(await repository.getTask('id-1'), isNull); // id tugas milik B
    });
  });

  group('pencarian (H04)', () {
    test('mencari di judul tanpa membedakan huruf besar/kecil', () async {
      await repository.addTask(title: 'Laporan Praktikum');
      await repository.addTask(title: 'Kuis Statistika');
      final dihapus = await repository.addTask(title: 'Laporan lama');
      await repository.deleteTask(dihapus);

      final hasil = await repository.searchTasks('  laporan ').first;
      expect(hasil.map((i) => i.task.title), ['Laporan Praktikum']);
    });

    test('kata kosong = daftar kosong', () async {
      await repository.addTask(title: 'Apa saja');
      expect(await repository.searchTasks('   ').first, isEmpty);
    });
  });

  group('detail tugas (layar 16)', () {
    test('watchTask ikut berubah dan jadi null saat dihapus', () async {
      final id = await repository.addTask(title: 'Kuis');
      final expectation = expectLater(
        repository.watchTask(id).map((t) => t?.status),
        emitsInOrder([TaskStatus.active, TaskStatus.done, null]),
      );
      await Future<void>.delayed(Duration.zero);
      await repository.setDone(id, done: true);
      await Future<void>.delayed(Duration.zero);
      await repository.deleteTask(id);
      await expectation;
    });

    test('progres sub-tugas, yang dihapus tidak dihitung', () async {
      final id = await repository.addTask(
        title: 'Laporan',
        subtasks: ['Bab 1', 'Bab 2', 'Bab 3', 'Bab 4'],
      );
      final subtasks = await repository.watchSubtasks(id).first;
      await repository.setSubtaskDone(subtasks[0].id, done: true);
      await repository.setSubtaskDone(subtasks[1].id, done: true);
      expect(await repository.watchSubtaskProgress(id).first, (
        done: 2,
        total: 4,
      ));

      await repository.deleteSubtask(subtasks[3].id);
      expect(await repository.watchSubtaskProgress(id).first, (
        done: 2,
        total: 3,
      ));
    });
  });

  group('sub-tugas (H01)', () {
    test('tambah di urutan terakhir, ganti judul, hapus, urungkan', () async {
      final taskId = await repository.addTask(
        title: 'Laporan',
        subtasks: ['Bab 1', 'Bab 2'],
      );

      final baru = await repository.addSubtask(taskId, 'Bab 3');
      var subtasks = await repository.watchSubtasks(taskId).first;
      expect(subtasks.map((s) => (s.title, s.position)), [
        ('Bab 1', 0),
        ('Bab 2', 1),
        ('Bab 3', 2),
      ]);

      final bab1 = subtasks.first.id;
      await repository.renameSubtask(baru, 'Penutup');
      await repository.deleteSubtask(bab1);
      subtasks = await repository.watchSubtasks(taskId).first;
      expect(subtasks.map((s) => s.title), ['Bab 2', 'Penutup']);

      await repository.restoreSubtask(bab1);
      subtasks = await repository.watchSubtasks(taskId).first;
      expect(subtasks.map((s) => s.title), ['Bab 1', 'Bab 2', 'Penutup']);

      final operations = (await queueEntries())
          .where((q) => q.targetTable == 'subtasks')
          .map((q) => q.operation);
      expect(operations, [
        SyncOperation.insert, // Bab 1
        SyncOperation.insert, // Bab 2
        SyncOperation.insert, // Bab 3
        SyncOperation.update, // ganti judul
        SyncOperation.delete, // hapus Bab 1
        SyncOperation.update, // urungkan
      ]);
    });

    test('sub-tugas pertama dari tugas tanpa sub-tugas di urutan 0', () async {
      final taskId = await repository.addTask(title: 'Kuis');
      await repository.addSubtask(taskId, 'Belajar bab 1');
      final subtask = (await repository.watchSubtasks(taskId).first).single;
      expect(subtask.position, 0);
    });

    test('tugas yang tidak ada atau milik akun lain = error', () async {
      final milikB = await repoFor('user-b').addTask(title: 'Milik B');
      await expectLater(
        repository.addSubtask(milikB, 'Numpang'),
        throwsStateError,
      );
      await expectLater(repository.deleteTask(milikB), throwsStateError);
    });
  });

  test('taskRepositoryProvider memakai id dev-lokal di build debug', () {
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
    );
    addTearDown(container.dispose);

    final repository = container.read(taskRepositoryProvider);
    expect(repository.userId, devLocalUserId);
  });
}
