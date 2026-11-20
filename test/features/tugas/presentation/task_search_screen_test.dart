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
import 'package:super_app/features/tugas/data/task_repository.dart';

import '../../../helpers/svg.dart';
import '../../../helpers/test_database.dart';

/// Figma H04: Senin 9 Nov 2026 09.40.
final _now = DateTime(2026, 11, 9, 9, 40);

Future<GoRouter> _pump(WidgetTester tester) async {
  tester.view
    ..physicalSize = const Size(412, 917)
    ..devicePixelRatio = 1
    ..padding = const FakeViewPadding(top: 32)
    ..viewPadding = const FakeViewPadding(top: 32);
  addTearDown(tester.view.reset);

  final database = testDatabase();
  addTearDown(database.close);
  await database
      .into(database.courses)
      .insert(
        CoursesCompanion.insert(
          id: 'c1',
          userId: devLocalUserId,
          semesterId: 's1',
          name: 'Pemrograman Mobile',
        ),
      );
  final tasks = TaskRepository(
    database,
    userId: devLocalUserId,
    now: () => _now,
  );
  await tasks.addTask(
    title: 'Buat to-do app dengan Riverpod',
    courseId: 'c1',
    dueAt: DateTime(2026, 11, 13, 23, 59),
  );
  final done = await tasks.addTask(title: 'Baca dokumentasi riverpod');
  await tasks.setDone(done, done: true);
  await tasks.addTask(title: 'Laporan praktikum modul 5');

  final router = buildAppRouter(initialLocation: AppRoutes.tugasCari);
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

void main() {
  testWidgets('H04: cari judul tugas, aktif dulu lalu selesai', (tester) async {
    await _pump(tester);
    expect(find.byType(AppTaskItem), findsNothing);

    await tester.enterText(find.byType(TextField), 'riverpod');
    await tester.pumpAndSettle();
    expect(find.text('2 HASIL UNTUK “RIVERPOD”'), findsOneWidget);
    expect(find.text('TUGAS · 2'), findsOneWidget);
    final titles = tester
        .widgetList<AppTaskItem>(find.byType(AppTaskItem))
        .map((item) => item.title)
        .toList();
    expect(titles, [
      'Buat to-do app dengan Riverpod',
      'Baca dokumentasi riverpod',
    ]);
    expect(find.text('Laporan praktikum modul 5'), findsNothing);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/tugas_h04_pencarian.png'),
    );
  });

  testWidgets('H04: tanpa hasil, lalu Close mengosongkan kueri', (
    tester,
  ) async {
    await _pump(tester);
    await tester.enterText(find.byType(TextField), 'skripsi');
    await tester.pumpAndSettle();
    expect(find.text('0 HASIL UNTUK “SKRIPSI”'), findsOneWidget);
    expect(find.byType(AppTaskItem), findsNothing);

    await tester.tap(find.bySemanticsLabel('Hapus pencarian'));
    await tester.pumpAndSettle();
    expect(find.textContaining('HASIL UNTUK'), findsNothing);
  });

  testWidgets('H04: ketuk hasil membuka Detail tugas', (tester) async {
    final router = await _pump(tester);
    await tester.enterText(find.byType(TextField), 'to-do');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buat to-do app dengan Riverpod'));
    await tester.pumpAndSettle();
    expect(router.state.matchedLocation, startsWith('/tugas/'));
    expect(router.state.matchedLocation, isNot(AppRoutes.tugasCari));
  });
}
