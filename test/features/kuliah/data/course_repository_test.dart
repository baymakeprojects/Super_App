import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/features/kuliah/data/course_repository.dart';

import '../../../helpers/test_database.dart';

/// Jumat 6 Nov 2026.
final _friday = DateTime(2026, 11, 6, 10, 2);

void main() {
  late AppDatabase db;
  late CourseRepository repository;

  setUp(() {
    db = testDatabase();
    repository = CourseRepository(db, userId: 'user-a');
  });

  tearDown(() => db.close());

  Future<void> semester(String id, String name, {bool active = false}) => db
      .into(db.semesters)
      .insert(
        SemestersCompanion.insert(
          id: id,
          userId: 'user-a',
          name: name,
          isActive: Value(active),
        ),
      );

  Future<void> course(
    String id,
    String name, {
    String semesterId = 's7',
    String userId = 'user-a',
    String? lecturer,
    DateTime? deletedAt,
  }) => db
      .into(db.courses)
      .insert(
        CoursesCompanion.insert(
          id: id,
          userId: userId,
          semesterId: semesterId,
          name: name,
          lecturer: Value(lecturer),
          deletedAt: Value(deletedAt),
        ),
      );

  Future<void> session(String courseId, int weekday, String startsAt) => db
      .into(db.classSessions)
      .insert(
        ClassSessionsCompanion.insert(
          id: '$courseId-$weekday-$startsAt',
          userId: 'user-a',
          courseId: courseId,
          weekday: weekday,
          startsAt: startsAt,
          endsAt: startsAt,
        ),
      );

  test('semester aktif; kelas hari ini dulu, lalu hari berikutnya', () async {
    await semester('s6', 'Semester 6');
    await semester('s7', 'Semester 7', active: true);
    await course('lama', 'Mata kuliah lama', semesterId: 's6');
    await course('pm', 'Pemrograman Mobile', lecturer: 'Bu Rina');
    await course('mp', 'Manajemen Proyek TI', lecturer: 'Pak Hendra');
    await course('kb', 'Kecerdasan Buatan');
    await course('sk', 'Skripsi');
    await session('pm', DateTime.friday, '08:00');
    await session('mp', DateTime.monday, '10:00');
    // Dua jadwal: yang dipakai yang paling dekat dari hari ini.
    await session('kb', DateTime.thursday, '07:00');
    await session('kb', DateTime.friday, '10:00');

    final options = await repository.loadCourseOptions(now: _friday);

    expect(options.semesterName, 'Semester 7');
    expect(options.courses.map((c) => (c.name, c.caption)), [
      ('Pemrograman Mobile', 'Jumat · 08.00 · Bu Rina'),
      ('Kecerdasan Buatan', 'Jumat · 10.00'),
      ('Manajemen Proyek TI', 'Senin · 10.00 · Pak Hendra'),
      ('Skripsi', null),
    ]);
  });

  test('tanpa semester aktif: semua mata kuliah milik akun ini', () async {
    await course('a', 'Algoritma', semesterId: 'x');
    await course('b', 'Basis Data', semesterId: 'y');
    await course('c', 'Punya akun lain', userId: 'user-b');
    await course('d', 'Sudah dihapus', deletedAt: _friday);

    final options = await repository.loadCourseOptions(now: _friday);

    expect(options.semesterName, isNull);
    expect(options.courses.map((c) => c.name), ['Algoritma', 'Basis Data']);
  });

  CourseInput input({
    String name = 'Interaksi Manusia dan Komputer',
    int weekday = DateTime.thursday,
    String startsAt = '13:00',
    String endsAt = '14:40',
  }) => (
    name: name,
    lecturer: 'Bu Maya',
    room: 'Lab 2, Gedung C',
    credits: 3,
    weekday: weekday,
    startsAt: startsAt,
    endsAt: endsAt,
  );

  test('tambah mata kuliah + jadwal, tampil di jadwal semesternya', () async {
    await semester('s7', 'Semester 7', active: true);
    final id = await repository.addCourse(semesterId: 's7', input: input());
    await repository.addCourse(
      semesterId: 's7',
      input: input(name: 'Pagi', weekday: DateTime.monday, startsAt: '07:00'),
    );
    await repository.addCourse(
      semesterId: 's6',
      input: input(name: 'Lama'),
    );

    final course = await repository.getCourse(id);
    expect(
      (course!.name, course.lecturer, course.room, course.credits),
      ('Interaksi Manusia dan Komputer', 'Bu Maya', 'Lab 2, Gedung C', 3),
    );
    final schedule = await repository.watchSchedule('s7').first;
    expect(
      schedule.map(
        (e) => (e.course.name, e.session.weekday, e.session.startsAt, e.room),
      ),
      [
        ('Pagi', DateTime.monday, '07:00', 'Lab 2, Gedung C'),
        (
          'Interaksi Manusia dan Komputer',
          DateTime.thursday,
          '13:00',
          'Lab 2, Gedung C',
        ),
      ],
    );
    final queue = await db.select(db.syncQueue).get();
    expect(queue.map((q) => q.targetTable).toSet(), {
      'courses',
      'class_sessions',
    });
  });

  test('ubah mata kuliah mengganti jadwal pertamanya', () async {
    final id = await repository.addCourse(semesterId: 's7', input: input());
    await repository.updateCourse(
      id,
      input: input(name: 'IMK', weekday: DateTime.friday, startsAt: '08:00'),
    );

    expect((await repository.getCourse(id))!.name, 'IMK');
    final sessions = await repository.getSessions(id);
    expect(sessions.single.weekday, DateTime.friday);
    expect(sessions.single.startsAt, '08:00');
  });

  test('ubah mata kuliah tanpa jadwal menambah jadwal', () async {
    await course('lama', 'Tanpa jadwal');
    await repository.updateCourse('lama', input: input(name: 'Ada jadwal'));
    expect((await repository.getSessions('lama')).single.startsAt, '13:00');
  });

  test('ubah mata kuliah akun lain = error', () async {
    await course('b', 'Milik B', userId: 'user-b');
    await expectLater(
      repository.updateCourse('b', input: input()),
      throwsStateError,
    );
  });

  test('nama hari dan jam tampilan', () {
    expect(CourseRepository.weekdayName(DateTime.friday), 'Jumat');
    expect(CourseRepository.displayTime('08:00'), '08.00');
  });
}
