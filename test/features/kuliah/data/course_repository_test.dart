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
}
