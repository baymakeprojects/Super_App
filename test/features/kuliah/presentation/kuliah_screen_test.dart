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
import 'package:super_app/features/kuliah/data/course_repository.dart';
import 'package:super_app/features/kuliah/data/semester_repository.dart';

import '../../../helpers/svg.dart';
import '../../../helpers/test_database.dart';

/// "Sekarang" seperti frame 04 dan K1: Jumat 6 Nov 2026 09.10.
final _now = DateTime(2026, 11, 6, 9, 10);

const Size _phone = Size(412, 917);
const double _statusBar = 32;

Future<GoRouter> _pumpKuliah(
  WidgetTester tester, {
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

  final router = buildAppRouter(initialLocation: AppRoutes.kuliah);
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
  return router;
}

Future<String> _seedSemester(AppDatabase db) => SemesterRepository(
  db,
  userId: devLocalUserId,
).addSemester(name: 'Semester 7', startsOn: DateTime(2026, 9), active: true);

/// Isi contoh frame 04.
Future<void> _seedFigma(AppDatabase db) async {
  final semesterId = await _seedSemester(db);
  final courses = CourseRepository(db, userId: devLocalUserId);
  for (final (name, room, lecturer, start, end) in [
    ('Pemrograman Mobile', 'Ruang 301', 'Bu Rina', '08:00', '09:40'),
    ('Kecerdasan Buatan', 'Ruang 204', 'Pak Andi', '10:00', '11:40'),
    ('Metodologi Penelitian', 'Ruang 105', 'Bu Sari', '13:00', '14:40'),
  ]) {
    await courses.addCourse(
      semesterId: semesterId,
      input: (
        name: name,
        lecturer: lecturer,
        room: room,
        credits: 3,
        weekday: DateTime.friday,
        startsAt: start,
        endsAt: end,
      ),
    );
  }
}

void main() {
  group('golden sama dengan Figma', () {
    testWidgets('04 Kuliah (15:218)', (tester) async {
      await _pumpKuliah(tester, seed: _seedFigma);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/kuliah_04.png'),
      );
    });

    testWidgets('K1 Kuliah kosong (140:4698)', (tester) async {
      await _pumpKuliah(tester, seed: _seedSemester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/kuliah_k1_kosong.png'),
      );
    });
  });

  group('perilaku', () {
    testWidgets('Day Pill mengganti hari', (tester) async {
      await _pumpKuliah(tester, seed: _seedFigma);
      expect(find.text('3 KELAS'), findsOneWidget);
      expect(find.text('Sedang berlangsung'.toUpperCase()), findsOneWidget);

      await tester.tap(find.text('SAB'));
      await tester.pumpAndSettle();
      expect(find.text('Sabtu, 7 November'), findsOneWidget);
      expect(find.text('0 KELAS'), findsOneWidget);
      expect(find.byType(AppClassItem), findsNothing);
    });

    testWidgets('ikon +, kelas, dan K1 membuka rute yang benar', (
      tester,
    ) async {
      final router = await _pumpKuliah(tester, seed: _seedFigma);

      await tester.tap(find.byType(AppCircleButton));
      await tester.pumpAndSettle();
      expect(find.text('Jadwal baru'), findsWidgets);
      router.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kecerdasan Buatan'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, startsWith('/kuliah/'));
    });

    testWidgets('K1: tombol dan tautan setup awal', (tester) async {
      final router = await _pumpKuliah(tester);
      expect(find.text('Belum ada jadwal kuliah'), findsOneWidget);
      // Belum ada semester aktif: label semester disembunyikan.
      expect(find.textContaining('SEMESTER'), findsNothing);

      await tester.tap(find.text('ATAU ISI LEWAT SETUP AWAL'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, AppRoutes.setupJadwal);
    });
  });
}
