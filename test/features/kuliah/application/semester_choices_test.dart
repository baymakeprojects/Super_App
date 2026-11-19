import 'package:flutter_test/flutter_test.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/features/kuliah/application/academic_term.dart';
import 'package:super_app/features/kuliah/application/semester_choices.dart';
import 'package:super_app/features/kuliah/data/semester_repository.dart';

import '../../../helpers/test_database.dart';

final _today = DateTime(2026, 11, 6);

void main() {
  group('AcademicTerm', () {
    test('periode dari tanggal', () {
      expect(AcademicTerm.of(DateTime(2026, 11, 6)).label, 'Ganjil 2026/2027');
      expect(AcademicTerm.of(DateTime(2027, 1, 20)).label, 'Ganjil 2026/2027');
      expect(AcademicTerm.of(DateTime(2027, 3, 1)).label, 'Genap 2026/2027');
      expect(AcademicTerm.of(DateTime(2026, 8, 10)).label, 'Ganjil 2026/2027');
    });

    test('tanggal mulai, selesai, dan periode berikutnya', () {
      final ganjil = AcademicTerm.of(_today);
      expect(ganjil.startsOn, DateTime(2026, 9));
      expect(ganjil.endsOn, DateTime(2027, 1, 31));
      expect(ganjil.next.label, 'Genap 2026/2027');
      expect(ganjil.next.startsOn, DateTime(2027, 2));
      expect(ganjil.next.next.label, 'Ganjil 2027/2028');
    });

    test('keterangan P20 seperti contoh Figma', () {
      String? caption(AcademicTerm term) => semesterCaption(
        startsOn: term.startsOn,
        endsOn: term.endsOn,
        today: _today,
      );
      final now = AcademicTerm.of(_today);
      expect(caption(now), 'Sep 2026 – Jan 2027 · sedang berjalan');
      expect(caption(now.next), 'Mulai Feb 2027');
      expect(
        caption(const AcademicTerm(ganjil: false, startYear: 2025)),
        'Selesai',
      );
    });

    test('nomor semester dari nama', () {
      expect(semesterNumber('Semester 7'), 7);
      expect(semesterNumber('Skripsi'), isNull);
    });
  });

  group('pilihan P20', () {
    late AppDatabase db;
    late SemesterRepository repository;

    setUp(() {
      db = testDatabase();
      repository = SemesterRepository(db, userId: 'user-a');
    });

    tearDown(() => db.close());

    test('belum ada semester: semester ganjil 1–13 periode ini', () async {
      final choices = await loadSemesterChoices(repository, today: _today);
      expect(choices.next, isNull);
      expect(choices.options.map((c) => c.title), [
        for (final n in [1, 3, 5, 7, 9, 11, 13])
          'Semester $n · Ganjil 2026/2027',
      ]);
      expect(choices.options.any((c) => c.selected), isFalse);

      final id = await activateSemesterChoice(repository, choices.options[3]);
      final active = await repository.getActiveSemester();
      expect(
        (active!.id, active.name, active.startsOn),
        (id, 'Semester 7', DateTime(2026, 9)),
      );
    });

    test('sudah ada: aktif dulu, lalu terbaru; + Semester baru', () async {
      const s6 = AcademicTerm(ganjil: false, startYear: 2025);
      await repository.addSemester(
        name: 'Semester 6',
        startsOn: s6.startsOn,
        endsOn: s6.endsOn,
      );
      final s7 = AcademicTerm.of(_today);
      await repository.addSemester(
        name: 'Semester 7',
        startsOn: s7.startsOn,
        endsOn: s7.endsOn,
        active: true,
      );
      await repository.addSemester(
        name: 'Semester 8',
        startsOn: s7.next.startsOn,
        endsOn: s7.next.endsOn,
      );

      final choices = await loadSemesterChoices(repository, today: _today);
      expect(choices.options.map((c) => (c.title, c.caption, c.selected)), [
        (
          'Semester 7 · Ganjil 2026/2027',
          'Sep 2026 – Jan 2027 · sedang berjalan',
          true,
        ),
        ('Semester 8 · Genap 2026/2027', 'Mulai Feb 2027', false),
        ('Semester 6 · Genap 2025/2026', 'Selesai', false),
      ]);
      expect(choices.next!.title, 'Semester 9 · Ganjil 2027/2028');
    });
  });
}
