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
import 'package:super_app/features/tugas/application/task_snackbar.dart';
import 'package:super_app/features/tugas/data/task_repository.dart';

import '../../../helpers/svg.dart';
import '../../../helpers/test_database.dart';

/// "Sekarang" seperti frame Figma 03: Jumat 6 Nov 2026 07.40.
final _now = DateTime(2026, 11, 6, 7, 40);

/// Ukuran frame HP Figma; status bar Android setinggi 32.
const Size _phone = Size(412, 917);
const double _statusBar = 32;

class _App {
  _App(this.router, this.container, this.database);

  final GoRouter router;
  final ProviderContainer container;
  final AppDatabase database;
}

Future<_App> _pumpTugas(
  WidgetTester tester, {
  Future<void> Function(AppDatabase db, TaskRepository repository)? seed,
}) async {
  tester.view
    ..physicalSize = _phone
    ..devicePixelRatio = 1
    ..padding = const FakeViewPadding(top: _statusBar)
    ..viewPadding = const FakeViewPadding(top: _statusBar);
  addTearDown(tester.view.reset);

  final database = testDatabase();
  addTearDown(database.close);
  final repository = TaskRepository(
    database,
    userId: devLocalUserId,
    now: () => _now,
  );
  await seed?.call(database, repository);

  final router = buildAppRouter(initialLocation: AppRoutes.tugas);
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

/// Isi contoh frame 03.
Future<void> _seedFigma(AppDatabase db, TaskRepository repository) async {
  for (final (id, name) in [
    ('c1', 'Metodologi Penelitian'),
    ('c2', 'Pemrograman Mobile'),
    ('c3', 'Kecerdasan Buatan'),
    ('c4', 'Manajemen Proyek TI'),
    ('c5', 'Skripsi'),
  ]) {
    await db
        .into(db.courses)
        .insert(
          CoursesCompanion.insert(
            id: id,
            userId: devLocalUserId,
            semesterId: 's1',
            name: name,
          ),
        );
  }
  await repository.addTask(
    title: 'Revisi proposal penelitian',
    courseId: 'c1',
    dueAt: DateTime(2026, 11, 5, 23, 59),
  );
  await repository.addTask(
    title: 'Laporan praktikum modul 5',
    courseId: 'c2',
    dueAt: DateTime(2026, 11, 6, 23, 59),
  );
  await repository.addTask(
    title: 'Kuis bab 4',
    courseId: 'c3',
    dueAt: DateTime(2026, 11, 7, 13),
  );
  await repository.addTask(
    title: 'Presentasi kelompok',
    courseId: 'c4',
    dueAt: DateTime(2026, 11, 9, 10),
  );
  final done = await repository.addTask(
    title: 'Baca jurnal referensi',
    courseId: 'c5',
    dueAt: DateTime(2026, 11, 6, 7),
  );
  await repository.setDone(done, done: true);
}

/// Baca tugas lewat query biasa, bukan stream: stream drift mengirim hasil
/// lewat timer yang tidak berjalan di jam palsu widget test.
Future<Task> _taskByTitle(_App app, String title) => (app.database.select(
  app.database.tasks,
)..where((t) => t.title.equals(title))).getSingle();

void main() {
  group('golden sama dengan Figma', () {
    testWidgets('03 Tugas (14:127)', (tester) async {
      await _pumpTugas(tester, seed: _seedFigma);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/tugas_03.png'),
      );
    });

    testWidgets('E2 Tugas kosong (67:1978)', (tester) async {
      await _pumpTugas(tester);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/tugas_e2_kosong.png'),
      );
    });

    testWidgets('E4 Snackbar urungkan (67:2114)', (tester) async {
      final app = await _pumpTugas(tester, seed: _seedFigma);
      final laporan = await _taskByTitle(app, 'Laporan praktikum modul 5');
      await app.container
          .read(taskSnackbarProvider.notifier)
          .delete(laporan.id, laporan.title);
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/tugas_e4_snackbar.png'),
      );

      // Biarkan snackbar habis supaya tidak ada timer yang tertinggal.
      await tester.pump(appSnackbarDuration);
      await tester.pumpAndSettle();
    });
  });

  group('perilaku', () {
    testWidgets('tandai selesai: pindah ke Selesai + snackbar, lalu urungkan', (
      tester,
    ) async {
      final app = await _pumpTugas(tester, seed: _seedFigma);
      expect(find.text('4 AKTIF · 2 HARI INI'), findsOneWidget);

      final kuis = find.ancestor(
        of: find.text('Kuis bab 4'),
        matching: find.byType(AppTaskItem),
      );
      await tester.tap(
        find.descendant(of: kuis, matching: find.byType(AppCheckbox)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tugas “Kuis bab 4” selesai'), findsOneWidget);
      expect(find.text('3 AKTIF · 2 HARI INI'), findsOneWidget);
      expect(find.text('BESOK'), findsNothing); // kelompok Besok kosong

      await tester.tap(find.text('URUNGKAN'));
      await tester.pumpAndSettle();
      expect(find.text('Tugas “Kuis bab 4” selesai'), findsNothing);
      expect(find.text('4 AKTIF · 2 HARI INI'), findsOneWidget);
      final kuisTask = await _taskByTitle(app, 'Kuis bab 4');
      expect(kuisTask.status, TaskStatus.active);
    });

    testWidgets('snackbar hilang sendiri setelah 4 detik', (tester) async {
      await _pumpTugas(tester, seed: _seedFigma);
      final kuis = find.ancestor(
        of: find.text('Kuis bab 4'),
        matching: find.byType(AppTaskItem),
      );
      await tester.tap(
        find.descendant(of: kuis, matching: find.byType(AppCheckbox)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppSnackbar), findsOneWidget);

      await tester.pump(appSnackbarDuration);
      await tester.pumpAndSettle();
      expect(find.byType(AppSnackbar), findsNothing);
    });

    testWidgets('chip filter menyaring kelompok', (tester) async {
      await _pumpTugas(tester, seed: _seedFigma);

      // Teks chip juga muncul sebagai badge/label kelompok: cari di chip.
      Finder chip(String label) =>
          find.descendant(of: find.byType(AppChip), matching: find.text(label));

      await tester.tap(chip('HARI INI'));
      await tester.pumpAndSettle();
      expect(find.text('Revisi proposal penelitian'), findsOneWidget);
      expect(find.text('Kuis bab 4'), findsNothing);

      await tester.tap(chip('SELESAI'));
      await tester.pumpAndSettle();
      expect(find.text('Baca jurnal referensi'), findsOneWidget);
      expect(find.text('Revisi proposal penelitian'), findsNothing);
    });

    testWidgets('FAB, Cari, dan baris membuka rute yang benar', (tester) async {
      final app = await _pumpTugas(tester, seed: _seedFigma);

      // `push` menumpuk halaman di atas alamat terakhir, jadi yang dicek
      // judul layar yang terbuka (layar sementara W1-09).
      await tester.tap(find.bySemanticsLabel('Tugas baru'));
      await tester.pumpAndSettle();
      expect(find.text('Tugas baru'), findsOneWidget);
      app.router.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppCircleButton));
      await tester.pumpAndSettle();
      expect(find.text('Pencarian'), findsOneWidget);
      app.router.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kuis bab 4'));
      await tester.pumpAndSettle();
      expect(find.text('Detail tugas'), findsOneWidget);
    });

    testWidgets('kosong: tombol + Tambah tugas membuka Tugas baru', (
      tester,
    ) async {
      await _pumpTugas(tester);
      expect(find.text('BELUM ADA TUGAS'), findsOneWidget);

      await tester.tap(find.text('+ TAMBAH TUGAS'));
      await tester.pumpAndSettle();
      expect(find.text('Tugas baru'), findsOneWidget);
    });
  });
}
