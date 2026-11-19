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
import 'package:super_app/core/db/enums.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/features/auth/application/current_user_id_provider.dart';
import 'package:super_app/features/kuliah/data/course_repository.dart';
import 'package:super_app/features/kuliah/data/semester_repository.dart';
import 'package:super_app/features/tugas/data/task_repository.dart';

import '../../../helpers/svg.dart';
import '../../../helpers/test_database.dart';

/// "Sekarang" seperti status bar frame 20: Jumat 6 Nov 2026 09.15.
final _now = DateTime(2026, 11, 6, 9, 15);

const Size _phone = Size(412, 917);
const double _statusBar = 32;

class _App {
  _App(this.router, this.database, this.courseId);

  final GoRouter router;
  final AppDatabase database;
  final String courseId;
}

typedef _Seed = Future<String> Function(AppDatabase db);

Future<_App> _pump(WidgetTester tester, _Seed seed) async {
  tester.view
    ..physicalSize = _phone
    ..devicePixelRatio = 1
    ..padding = const FakeViewPadding(top: _statusBar)
    ..viewPadding = const FakeViewPadding(top: _statusBar);
  addTearDown(tester.view.reset);

  final database = testDatabase();
  addTearDown(database.close);
  final courseId = await seed(database);

  // Dibuka dari 04 seperti di app.
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
  unawaited(router.push(AppRoutes.kuliahDetail(courseId)));
  await tester.pumpAndSettle();
  return _App(router, database, courseId);
}

/// Isi contoh frame 20.
Future<String> _seedFigma(AppDatabase db) async {
  final semesterId = await SemesterRepository(
    db,
    userId: devLocalUserId,
  ).addSemester(name: 'Semester 7', startsOn: DateTime(2026, 9), active: true);
  final courseId = await CourseRepository(db, userId: devLocalUserId).addCourse(
    semesterId: semesterId,
    input: (
      name: 'Pemrograman Mobile',
      lecturer: 'Bu Rina',
      room: 'Ruang 301, Gedung B',
      credits: 3,
      weekday: DateTime.friday,
      startsAt: '08:00',
      endsAt: '09:40',
    ),
  );
  final tasks = TaskRepository(db, userId: devLocalUserId, now: () => _now);
  await tasks.addTask(
    title: 'Kuis state management',
    courseId: courseId,
    dueAt: DateTime(2026, 11, 9, 8),
  );
  await tasks.addTask(
    title: 'Laporan praktikum modul 5',
    courseId: courseId,
    dueAt: DateTime(2026, 11, 6, 23, 59),
  );
  final done = await tasks.addTask(title: 'Sudah selesai', courseId: courseId);
  await tasks.setDone(done, done: true);
  await tasks.addTask(title: 'Tugas lain', courseId: null);
  return courseId;
}

void main() {
  testWidgets('golden: 20 Detail mata kuliah MVP (158:15146)', (tester) async {
    await _pump(tester, _seedFigma);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/kuliah_20_detail.png'),
    );
  });

  group('perilaku', () {
    testWidgets('info mata kuliah dan tugas aktif', (tester) async {
      await _pump(tester, _seedFigma);
      expect(find.text('3 SKS · SEMESTER 7'), findsOneWidget);
      expect(find.text('Jumat · 08.00–09.40'), findsOneWidget);
      expect(find.text('TUGAS AKTIF · 2'), findsOneWidget);
      final titles = tester
          .widgetList<AppTaskItem>(find.byType(AppTaskItem))
          .map((t) => t.title);
      expect(titles, ['Laporan praktikum modul 5', 'Kuis state management']);
      expect(find.text('Pemrograman Mobile · Sen 08.00'), findsOneWidget);
    });

    testWidgets('centang tugas: selesai dan hilang dari daftar', (
      tester,
    ) async {
      final app = await _pump(tester, _seedFigma);
      final kuis = find.ancestor(
        of: find.text('Kuis state management'),
        matching: find.byType(AppTaskItem),
      );
      await tester.tap(
        find.descendant(of: kuis, matching: find.byType(AppCheckbox)),
      );
      await tester.pumpAndSettle();

      expect(find.text('TUGAS AKTIF · 1'), findsOneWidget);
      final task = await (app.database.select(
        app.database.tasks,
      )..where((t) => t.title.equals('Kuis state management'))).getSingle();
      expect(task.status, TaskStatus.done);
    });

    testWidgets('ketuk tugas membuka Detail tugas; Edit membuka H02', (
      tester,
    ) async {
      final app = await _pump(tester, _seedFigma);
      await tester.tap(find.text('Laporan praktikum modul 5'));
      await tester.pumpAndSettle();
      expect(find.text('Detail tugas'), findsOneWidget);
      app.router.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Ubah jadwal'));
      await tester.pumpAndSettle();
      expect(
        app.router.state.matchedLocation,
        AppRoutes.kuliahEdit(app.courseId),
      );
      expect(find.text('Pemrograman Mobile'), findsOneWidget);
    });

    testWidgets('tanpa data: baris kosong disembunyikan, tugas aktif · 0', (
      tester,
    ) async {
      await _pump(tester, (db) async {
        final semesterId = await SemesterRepository(
          db,
          userId: devLocalUserId,
        ).addSemester(name: 'Semester 7', active: true);
        return CourseRepository(db, userId: devLocalUserId).addCourse(
          semesterId: semesterId,
          input: (
            name: 'Skripsi',
            lecturer: null,
            room: null,
            credits: null,
            weekday: DateTime.monday,
            startsAt: '10:00',
            endsAt: '11:00',
          ),
        );
      });
      expect(find.text('SEMESTER 7'), findsOneWidget);
      expect(find.text('TUGAS AKTIF · 0'), findsOneWidget);
      // Ikon: panah, edit, dan jam saja (tanpa dosen dan ruang).
      expect(find.byType(AppIcon), findsNWidgets(3));
    });
  });
}
