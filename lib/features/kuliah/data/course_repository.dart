import 'package:drift/drift.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/db/enums.dart';
import 'package:super_app/core/sync/sync_queue_writer.dart';
import 'package:super_app/core/utils/date_format.dart';
import 'package:super_app/core/utils/uuid.dart';

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

/// Satu kelas di jadwal 04: jadwal (hari + jam) beserta mata kuliahnya.
class ScheduleEntry {
  const ScheduleEntry({required this.session, required this.course});

  final ClassSession session;
  final Course course;

  /// Ruang kelas: ruang di jadwal, atau ruang mata kuliah.
  String? get room => session.room ?? course.room;
}

/// Isi H02 Jadwal baru: satu mata kuliah dengan satu jadwal mingguan.
/// [weekday] 1 = Senin … 7 = Minggu; jam berformat `HH:mm`.
typedef CourseInput = ({
  String name,
  String? lecturer,
  String? room,
  int? credits,
  int weekday,
  String startsAt,
  String endsAt,
});

/// Data mata kuliah dan jadwalnya. Pola sama dengan `TaskRepository`: baca
/// disaring per akun dan `deleted_at`, tulis + antrean sinkron dalam satu
/// transaksi.
class CourseRepository {
  CourseRepository(
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

  static const String _coursesTable = 'courses';
  static const String _sessionsTable = 'class_sessions';

  // ---------------------------------------------------------------------------
  // Baca
  // ---------------------------------------------------------------------------

  /// Semua kelas mingguan di semester [semesterId], urut hari lalu jam
  /// (layar 04 Kuliah).
  Stream<List<ScheduleEntry>> watchSchedule(String semesterId) {
    final sessions = _database.classSessions;
    final courses = _database.courses;
    final query =
        _database.select(sessions).join([
            innerJoin(courses, courses.id.equalsExp(sessions.courseId)),
          ])
          ..where(
            sessions.userId.equals(userId) &
                sessions.deletedAt.isNull() &
                courses.userId.equals(userId) &
                courses.deletedAt.isNull() &
                courses.semesterId.equals(semesterId),
          )
          ..orderBy([
            OrderingTerm(expression: sessions.weekday),
            OrderingTerm(expression: sessions.startsAt),
            OrderingTerm(expression: courses.name),
          ]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          ScheduleEntry(
            session: row.readTable(sessions),
            course: row.readTable(courses),
          ),
      ],
    );
  }

  SimpleSelectStatement<$CoursesTable, Course> _courseQuery(String id) {
    return _database.select(_database.courses)..where(
      (c) => c.userId.equals(userId) & c.id.equals(id) & c.deletedAt.isNull(),
    );
  }

  SimpleSelectStatement<$ClassSessionsTable, ClassSession> _sessionsQuery(
    String courseId,
  ) {
    return _database.select(_database.classSessions)
      ..where(
        (s) =>
            s.userId.equals(userId) &
            s.courseId.equals(courseId) &
            s.deletedAt.isNull(),
      )
      ..orderBy([
        (s) => OrderingTerm(expression: s.weekday),
        (s) => OrderingTerm(expression: s.startsAt),
      ]);
  }

  /// Satu mata kuliah (layar 20). `null` kalau tidak ada atau dihapus.
  Stream<Course?> watchCourse(String id) =>
      _courseQuery(id).watchSingleOrNull();

  Future<Course?> getCourse(String id) => _courseQuery(id).getSingleOrNull();

  /// Jadwal mingguan satu mata kuliah, urut hari lalu jam.
  Stream<List<ClassSession>> watchSessions(String courseId) =>
      _sessionsQuery(courseId).watch();

  Future<List<ClassSession>> getSessions(String courseId) =>
      _sessionsQuery(courseId).get();

  // ---------------------------------------------------------------------------
  // Tulis
  // ---------------------------------------------------------------------------

  /// Menambah mata kuliah dengan satu jadwal mingguan (H02). Mengembalikan
  /// id mata kuliah.
  Future<String> addCourse({
    required String semesterId,
    required CourseInput input,
  }) {
    return _database.transaction(() async {
      final id = _newId();
      final now = _now();
      await _database
          .into(_database.courses)
          .insert(
            CoursesCompanion.insert(
              id: id,
              userId: userId,
              semesterId: semesterId,
              name: input.name,
              lecturer: Value(input.lecturer),
              room: Value(input.room),
              credits: Value(input.credits),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      await _queue.enqueue(
        table: _coursesTable,
        rowId: id,
        operation: SyncOperation.insert,
      );
      await _insertSession(id, input);
      return id;
    });
  }

  /// Mengubah mata kuliah dan jadwal pertamanya (H02 mode ubah). Kalau
  /// belum punya jadwal, jadwal baru ditambahkan.
  Future<void> updateCourse(String id, {required CourseInput input}) {
    return _database.transaction(() async {
      final now = _now();
      final changed =
          await (_database.update(
            _database.courses,
          )..where((c) => c.userId.equals(userId) & c.id.equals(id))).write(
            CoursesCompanion(
              name: Value(input.name),
              lecturer: Value(input.lecturer),
              room: Value(input.room),
              credits: Value(input.credits),
              updatedAt: Value(now),
            ),
          );
      if (changed == 0) throw StateError('Mata kuliah $id tidak ditemukan');
      await _queue.enqueue(
        table: _coursesTable,
        rowId: id,
        operation: SyncOperation.update,
      );

      final sessions = await getSessions(id);
      if (sessions.isEmpty) {
        await _insertSession(id, input);
        return;
      }
      final first = sessions.first;
      await (_database.update(
        _database.classSessions,
      )..where((s) => s.userId.equals(userId) & s.id.equals(first.id))).write(
        ClassSessionsCompanion(
          weekday: Value(input.weekday),
          startsAt: Value(input.startsAt),
          endsAt: Value(input.endsAt),
          updatedAt: Value(now),
        ),
      );
      await _queue.enqueue(
        table: _sessionsTable,
        rowId: first.id,
        operation: SyncOperation.update,
      );
    });
  }

  Future<void> _insertSession(String courseId, CourseInput input) async {
    final id = _newId();
    final now = _now();
    await _database
        .into(_database.classSessions)
        .insert(
          ClassSessionsCompanion.insert(
            id: id,
            userId: userId,
            courseId: courseId,
            weekday: input.weekday,
            startsAt: input.startsAt,
            endsAt: input.endsAt,
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    await _queue.enqueue(
      table: _sessionsTable,
      rowId: id,
      operation: SyncOperation.insert,
    );
  }

  // ---------------------------------------------------------------------------
  // Pilihan mata kuliah (P03 di form tugas)
  // ---------------------------------------------------------------------------

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
        weekdayName(session.weekday),
        displayTime(session.startsAt),
      ],
      ?course.lecturer,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// "Jumat" untuk [weekday] 5 (1 = Senin).
  static String weekdayName(int weekday) =>
      AppDateFormat.weekday(DateTime(2024, 1, weekday)); // 1 Jan 2024 Senin

  /// "08.00" dari kolom jam `08:00`.
  static String displayTime(String hhmm) => hhmm.replaceFirst(':', '.');
}
