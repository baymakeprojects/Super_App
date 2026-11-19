import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/app.dart';
import 'package:super_app/app/router.dart';
import 'package:super_app/app/routes.dart';
import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/db/database_provider.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/features/auth/application/current_user_id_provider.dart';
import 'package:super_app/features/kuliah/application/academic_term.dart';
import 'package:super_app/features/kuliah/application/course_form_controller.dart';
import 'package:super_app/features/kuliah/application/semester_choices.dart';
import 'package:super_app/features/kuliah/data/course_repository.dart';
import 'package:super_app/features/kuliah/data/semester_repository.dart';
import 'package:super_app/features/kuliah/presentation/semester_sheet.dart';

import '../../../helpers/svg.dart';
import '../../../helpers/test_database.dart';

/// "Sekarang": Jumat 6 Nov 2026 10.15 (status bar frame H02).
final _now = DateTime(2026, 11, 6, 10, 15);

const Size _phone = Size(412, 917);
const double _statusBar = 32;

class _App {
  _App(this.router, this.container, this.database);

  final GoRouter router;
  final ProviderContainer container;
  final AppDatabase database;

  CourseFormController form([String? id]) =>
      container.read(courseFormProvider(id).notifier);

  Future<List<Course>> courses() => database.select(database.courses).get();
}

Future<_App> _pump(
  WidgetTester tester,
  String location, {
  Future<void> Function(AppDatabase db)? seed,
}) async {
  tester.view
    ..physicalSize = _phone
    ..devicePixelRatio = 1
    ..padding = const FakeViewPadding(top: _statusBar)
    ..viewPadding = const FakeViewPadding(top: _statusBar);
  addTearDown(tester.view.reset);

  final database = testDatabase();
  addTearDown(database.close);
  await seed?.call(database);

  final router = buildAppRouter(initialLocation: location);
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      appRouterProvider.overrideWithValue(router),
      appDatabaseProvider.overrideWithValue(database),
      clockProvider.overrideWithValue(() => _now),
    ],
  );
  addTearDown(container.dispose);

  await precacheAppIcons(tester);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const SuperApp()),
  );
  await tester.pumpAndSettle();
  return _App(router, container, database);
}

SemesterRepository _semesters(AppDatabase db) =>
    SemesterRepository(db, userId: devLocalUserId);

Future<String> _seedActive(AppDatabase db) {
  final term = AcademicTerm.of(_now);
  return _semesters(db).addSemester(
    name: 'Semester 7',
    startsOn: term.startsOn,
    endsOn: term.endsOn,
    active: true,
  );
}

Finder _input(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(AppInput)),
  matching: find.byType(TextField),
);

/// Isi contoh frame H02.
Future<void> _fillFigma(WidgetTester tester, _App app) async {
  await tester.enterText(_input('DOSEN'), 'Bu Maya');
  app.form()
    ..setLecturer('Bu Maya')
    ..setWeekday(DateTime.thursday)
    ..setStart(13 * 60)
    ..setEnd(14 * 60 + 40);
  await tester.enterText(_input('RUANG'), 'Lab 2, Gedung C');
  // Judul diketik terakhir supaya kolomnya Focus seperti di Figma.
  await tester.enterText(
    _input('NAMA MATA KULIAH'),
    'Interaksi Manusia dan Komputer',
  );
  await tester.pumpAndSettle();
}

void main() {
  group('golden sama dengan Figma', () {
    testWidgets('H02 Jadwal baru (54:2356)', (tester) async {
      final app = await _pump(tester, AppRoutes.kuliahJadwalBaru);
      await _fillFigma(tester, app);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/kuliah_h02_jadwal_baru.png'),
      );
    });

    testWidgets('P20 Pilih semester (85:4227)', (tester) async {
      final app = await _pump(
        tester,
        AppRoutes.kuliahJadwalBaru,
        seed: (db) async {
          final repository = _semesters(db);
          const s6 = AcademicTerm(ganjil: false, startYear: 2025);
          await repository.addSemester(
            name: 'Semester 6',
            startsOn: s6.startsOn,
            endsOn: s6.endsOn,
          );
          await _seedActive(db);
          final s8 = AcademicTerm.of(_now).next;
          await repository.addSemester(
            name: 'Semester 8',
            startsOn: s8.startsOn,
            endsOn: s8.endsOn,
          );
        },
      );
      // Sheet dibuka langsung (di app P20 hanya muncul saat belum ada
      // semester aktif), supaya isinya sama dengan contoh Figma.
      final choices = await loadSemesterChoices(
        _semesters(app.database),
        today: _now,
      );
      final context = tester.element(find.byType(AppActionBar));
      unawaited(showSemesterSheet(context: context, choices: choices));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/kuliah_p20_semester.png'),
      );
    });
  });

  group('perilaku', () {
    testWidgets('pertama kali: P20, lalu jadwal tampil di 04', (tester) async {
      final app = await _pump(tester, AppRoutes.kuliahJadwalBaru);
      await tester.enterText(_input('NAMA MATA KULIAH'), 'Pemrograman Mobile');
      await tester.enterText(_input('RUANG'), 'Ruang 301');
      await tester.tap(find.text('SIMPAN JADWAL'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih semester'), findsOneWidget);
      await tester.tap(find.text('Semester 7 · Ganjil 2026/2027'));
      await tester.pumpAndSettle();

      expect(app.router.state.matchedLocation, AppRoutes.kuliah);
      expect(find.text('SEMESTER 7 · MINGGU KE-10'), findsOneWidget);
      expect(find.text('Pemrograman Mobile'), findsOneWidget);
      expect(find.text('08.00'), findsOneWidget);

      final course = (await app.courses()).single;
      expect((course.room, course.credits), ('Ruang 301', 3));
    });

    testWidgets('P20 ditutup: tidak tersimpan, tetap di form', (tester) async {
      final app = await _pump(tester, AppRoutes.kuliahJadwalBaru);
      await tester.enterText(_input('NAMA MATA KULIAH'), 'IMK');
      await tester.tap(find.text('SIMPAN JADWAL'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Tutup').last);
      await tester.pumpAndSettle();

      expect(app.router.state.matchedLocation, AppRoutes.kuliahJadwalBaru);
      expect(await app.courses(), isEmpty);
    });

    testWidgets('isian belum lengkap: pesan di kolomnya', (tester) async {
      final app = await _pump(
        tester,
        AppRoutes.kuliahJadwalBaru,
        seed: _seedActive,
      );
      app.form()
        ..setStart(13 * 60)
        ..setEnd(12 * 60);
      await tester.tap(find.text('SIMPAN JADWAL'));
      await tester.pumpAndSettle();

      expect(find.text('Nama mata kuliah wajib diisi'), findsOneWidget);
      expect(find.text('Jam selesai harus setelah jam mulai'), findsOneWidget);
      expect(await app.courses(), isEmpty);
    });

    testWidgets('jam mulai menggeser jam selesai lewat P02', (tester) async {
      await _pump(tester, AppRoutes.kuliahJadwalBaru, seed: _seedActive);
      expect(find.text('08.00'), findsOneWidget);
      expect(find.text('09.40'), findsOneWidget);

      await tester.tap(find.text('08.00'));
      await tester.pumpAndSettle();
      expect(find.text('Jam mulai · Jumat'), findsOneWidget);
      await tester.tap(find.text('12.00'));
      await tester.pump();
      await tester.tap(find.text('PILIH'));
      await tester.pumpAndSettle();

      expect(find.text('12.00'), findsOneWidget);
      expect(find.text('13.40'), findsOneWidget);
    });

    testWidgets('ubah jadwal: isian awal dan simpan perubahan', (tester) async {
      late String id;
      final app = await _pump(
        tester,
        AppRoutes.kuliah,
        seed: (db) async {
          final semesterId = await _seedActive(db);
          id = await CourseRepository(db, userId: devLocalUserId).addCourse(
            semesterId: semesterId,
            input: (
              name: 'Pemrograman Mobile',
              lecturer: 'Bu Rina',
              room: 'Ruang 301',
              credits: 3,
              weekday: DateTime.friday,
              startsAt: '08:00',
              endsAt: '09:40',
            ),
          );
        },
      );
      unawaited(app.router.push(AppRoutes.kuliahEdit(id)));
      await tester.pumpAndSettle();

      expect(find.text('Ubah jadwal'), findsOneWidget);
      expect(find.text('Bu Rina'), findsOneWidget);
      await tester.enterText(
        _input('NAMA MATA KULIAH'),
        'Pemrograman Mobile 2',
      );
      await tester.tap(find.text('4 SKS'));
      await tester.tap(find.text('Sen'));
      await tester.pump();
      await tester.tap(find.text('SIMPAN PERUBAHAN'));
      await tester.pumpAndSettle();

      expect(app.router.state.matchedLocation, AppRoutes.kuliah);
      final course = (await app.courses()).single;
      expect((course.name, course.credits), ('Pemrograman Mobile 2', 4));
      final session =
          (await app.database.select(app.database.classSessions).get()).single;
      expect(session.weekday, DateTime.monday);
    });
  });
}
