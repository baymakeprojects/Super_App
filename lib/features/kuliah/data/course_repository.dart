import 'package:drift/drift.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/utils/date_format.dart';

/// Satu mata kuliah di pop-up P03 Pilih mata kuliah.
class CourseOption {
  const CourseOption({required this.id, required this.name, this.caption});

  final String id;
  final String name;

  /// "Jumat · 08.00 · Bu Rina": jadwal pertama dan dosen. `null` kalau
  /// keduanya belum diisi.
  final String? caption;
}

/// Isi pop-up P03: nama semester aktif dan daftar mata kuliahnya.
class CourseOptions {
  const CourseOptions({required this.semesterName, required this.courses});

  /// `null` = belum ada semester aktif.
  final String? semesterName;
  final List<CourseOption> courses;
}

/// Data mata kuliah. Untuk sekarang hanya bacaan untuk P03; tambah, ubah,
/// dan hapus menyusul di W2-07.
class CourseRepository {
  CourseRepository(this._database, {required this.userId});

  final AppDatabase _database;

  /// Pemilik data (akun yang sedang login).
  final String userId;

  /// Mata kuliah semester aktif, kelas hari ini dulu lalu hari berikutnya
  /// (urutan contoh P03 pada hari Jumat). Kalau belum ada semester aktif,
  /// semua mata kuliah ditampilkan.
  Future<CourseOptions> loadCourseOptions({required DateTime now}) async {
    final semester =
        await (_database.select(_database.semesters)
              ..where(
                (s) =>
                    s.userId.equals(userId) &
                    s.isActive.equals(true) &
                    s.deletedAt.isNull(),
              )
              ..limit(1))
            .getSingleOrNull();

    final courseQuery = _database.select(_database.courses)
      ..where((c) => c.userId.equals(userId) & c.deletedAt.isNull());
    if (semester != null) {
      courseQuery.where((c) => c.semesterId.equals(semester.id));
    }
    final courses = await courseQuery.get();

    final sessions =
        await (_database.select(_database.classSessions)..where(
              (s) =>
                  s.userId.equals(userId) &
                  s.deletedAt.isNull() &
                  s.courseId.isIn(courses.map((c) => c.id)),
            ))
            .get();

    // Jarak hari dari hari ini (0 = hari ini, 6 = kemarin), lalu jam mulai.
    int daysFromToday(ClassSession s) =>
        (s.weekday - now.weekday) % DateTime.daysPerWeek;
    int compareSessions(ClassSession a, ClassSession b) {
      final byDay = daysFromToday(a).compareTo(daysFromToday(b));
      return byDay != 0 ? byDay : a.startsAt.compareTo(b.startsAt);
    }

    final firstSession = <String, ClassSession>{};
    for (final session in [...sessions]..sort(compareSessions)) {
      firstSession.putIfAbsent(session.courseId, () => session);
    }

    final sorted = [...courses]
      ..sort((a, b) {
        final sa = firstSession[a.id];
        final sb = firstSession[b.id];
        // Mata kuliah tanpa jadwal di akhir, urut nama.
        if (sa == null || sb == null) {
          if (sa != sb) return sa == null ? 1 : -1;
          return a.name.compareTo(b.name);
        }
        final bySession = compareSessions(sa, sb);
        return bySession != 0 ? bySession : a.name.compareTo(b.name);
      });

    return CourseOptions(
      semesterName: semester?.name,
      courses: [
        for (final course in sorted)
          CourseOption(
            id: course.id,
            name: course.name,
            caption: _caption(course, firstSession[course.id]),
          ),
      ],
    );
  }

  static String? _caption(Course course, ClassSession? session) {
    final parts = [
      if (session != null) ...[
        AppDateFormat.weekday(_weekdayDate(session.weekday)),
        // Kolom jam disimpan "HH:mm"; tampilan app memakai titik.
        session.startsAt.replaceFirst(':', '.'),
      ],
      ?course.lecturer,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// Tanggal mana saja dengan hari [weekday] (1 = Senin), hanya untuk
  /// mengambil nama harinya.
  static DateTime _weekdayDate(int weekday) => DateTime(2024, 1, weekday);
}
