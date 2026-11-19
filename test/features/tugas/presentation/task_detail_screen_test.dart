import 'package:drift/drift.dart' show BooleanExpressionOperators, OrderingTerm;
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
import 'package:super_app/features/tugas/data/task_repository.dart';

import '../../../helpers/svg.dart';
import '../../../helpers/test_database.dart';

/// "Sekarang" seperti status bar frame 16: Jumat 6 Nov 2026 10.05.
final _now = DateTime(2026, 11, 6, 10, 5);

const Size _phone = Size(412, 917);
const double _statusBar = 32;

const String _title = 'Laporan praktikum modul 5';

class _App {
  _App(this.router, this.database, this.taskId);

  final GoRouter router;
  final AppDatabase database;
  final String taskId;

  Future<Task> task() => (database.select(
    database.tasks,
  )..where((t) => t.id.equals(taskId))).getSingle();

  Future<List<Subtask>> subtasks() =>
      (database.select(database.subtasks)
            ..where((s) => s.taskId.equals(taskId) & s.deletedAt.isNull())
            ..orderBy([(s) => OrderingTerm(expression: s.position)]))
          .get();
}

/// Isi tugas contoh; mengembalikan id tugas yang dibuka.
typedef _Seed = Future<String> Function(
  AppDatabase db,
  TaskRepository repository,
);

Future<_App> _pumpDetail(WidgetTester tester, _Seed seed) async {
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
  final taskId = await seed(database, repository);

  // Rute anak: di bawahnya ada 03 Tugas, jadi kembali = ke daftar.
  final router = buildAppRouter(initialLocation: AppRoutes.tugasDetail(taskId));
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
  return _App(router, database, taskId);
}

Future<void> _course(AppDatabase db) => db
    .into(db.courses)
    .insert(
      CoursesCompanion.insert(
        id: 'c2',
        userId: devLocalUserId,
        semesterId: 's7',
        name: 'Pemrograman Mobile',
      ),
    );

/// Isi contoh frame 16 dan P05.
Future<String> _seedFigma16(AppDatabase db, TaskRepository repository) async {
  await _course(db);
  final id = await repository.addTask(
    title: _title,
    courseId: 'c2',
    dueAt: DateTime(2026, 11, 6, 23, 59),
    priority: TaskPriority.medium,
    notes:
        'Pakai template dari asisten lab. Kumpulkan lewat e-learning '
        'dalam bentuk PDF.',
    subtasks: [
      'Kerjakan kode praktikum',
      'Ambil screenshot hasil',
      'Tulis analisis & kesimpulan',
      'Export PDF dan kumpulkan',
    ],
  );
  final subtasks = await repository.getSubtasks(id);
  for (final s in subtasks.take(2)) {
    await repository.setSubtaskDone(s.id, done: true);
  }
  return id;
}

/// Isi contoh frame H01: dua sub-tugas belum selesai, tanpa catatan.
Future<String> _seedFigmaH01(AppDatabase db, TaskRepository repository) async {
  await _course(db);
  return repository.addTask(
    title: _title,
    courseId: 'c2',
    dueAt: DateTime(2026, 11, 6, 23, 59),
    priority: TaskPriority.medium,
    subtasks: ['Kerjakan kode praktikum', 'Tulis analisis & kesimpulan'],
  );
}

/// Biarkan snackbar habis supaya tidak ada timer yang tertinggal.
Future<void> _waitSnackbar(WidgetTester tester) async {
  await tester.pump(appSnackbarDuration);
  await tester.pumpAndSettle();
}

void main() {
  group('golden sama dengan Figma', () {
    testWidgets('16 Detail tugas (30:1472)', (tester) async {
      await _pumpDetail(tester, _seedFigma16);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/tugas_16_detail.png'),
      );
    });

    testWidgets('P05 Konfirmasi hapus (50:611)', (tester) async {
      await _pumpDetail(tester, _seedFigma16);
      await tester.tap(find.text('HAPUS'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/tugas_p05_hapus.png'),
      );
    });

    testWidgets('H01 Edit tugas (54:2269)', (tester) async {
      await _pumpDetail(tester, _seedFigmaH01);
      await tester.tap(find.bySemanticsLabel('Edit tugas'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/tugas_h01_edit.png'),
      );
    });
  });

  group('perilaku', () {
    testWidgets('centang sub-tugas langsung tersimpan', (tester) async {
      final app = await _pumpDetail(tester, _seedFigma16);
      expect(find.text('2/4 SELESAI'), findsOneWidget);

      await tester.tap(find.text('Tulis analisis & kesimpulan'));
      await tester.pumpAndSettle();

      expect(find.text('3/4 SELESAI'), findsOneWidget);
      final subtasks = await app.subtasks();
      expect(subtasks.map((s) => s.isDone), [true, true, true, false]);
    });

    testWidgets('Tandai selesai: kembali ke 03 dengan snackbar Urungkan', (
      tester,
    ) async {
      final app = await _pumpDetail(tester, _seedFigma16);
      await tester.tap(find.text('TANDAI SELESAI'));
      await tester.pumpAndSettle();

      expect(app.router.state.matchedLocation, AppRoutes.tugas);
      expect(find.text('Tugas “$_title” selesai'), findsOneWidget);
      expect((await app.task()).status, TaskStatus.done);
      await _waitSnackbar(tester);
    });

    testWidgets('tugas selesai: badge Selesai, Tandai belum selesai', (
      tester,
    ) async {
      final app = await _pumpDetail(tester, (db, repository) async {
        final id = await _seedFigma16(db, repository);
        await repository.setDone(id, done: true);
        return id;
      });
      expect(find.text('SELESAI'), findsOneWidget);

      await tester.tap(find.text('TANDAI BELUM SELESAI'));
      await tester.pumpAndSettle();

      expect(
        app.router.state.matchedLocation,
        AppRoutes.tugasDetail(app.taskId),
      );
      expect(find.text('TANDAI SELESAI'), findsOneWidget);
      expect(find.text('HARI INI'), findsOneWidget);
      expect((await app.task()).status, TaskStatus.active);
    });

    testWidgets('hapus lewat P05, lalu Urungkan dari 03', (tester) async {
      final app = await _pumpDetail(tester, _seedFigma16);
      await tester.tap(find.text('HAPUS'));
      await tester.pumpAndSettle();
      expect(
        find.text('“$_title” dan 4 sub-tugasnya akan dihapus.'),
        findsOneWidget,
      );
      // Konfirmasi hapus tanpa tombol tutup.
      expect(find.bySemanticsLabel('Tutup'), findsNothing);

      await tester.tap(find.text('HAPUS TUGAS'));
      await tester.pumpAndSettle();

      expect(app.router.state.matchedLocation, AppRoutes.tugas);
      expect(find.text('Tugas “$_title” dihapus'), findsOneWidget);
      expect((await app.task()).deletedAt, isNotNull);

      await tester.tap(find.text('URUNGKAN'));
      await tester.pumpAndSettle();
      expect((await app.task()).deletedAt, isNull);
      expect(find.text(_title), findsOneWidget);
    });

    testWidgets('P05 Batal tidak menghapus', (tester) async {
      final app = await _pumpDetail(tester, _seedFigma16);
      await tester.tap(find.text('HAPUS'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('BATAL'));
      await tester.pumpAndSettle();

      expect(find.text('Hapus tugas ini?'), findsNothing);
      expect((await app.task()).deletedAt, isNull);
    });

    testWidgets('P05 tanpa sub-tugas', (tester) async {
      await _pumpDetail(
        tester,
        (db, repository) => repository.addTask(title: 'Kuis'),
      );
      await tester.tap(find.text('HAPUS'));
      await tester.pumpAndSettle();
      expect(find.text('“Kuis” akan dihapus.'), findsOneWidget);
    });

    testWidgets('tanpa data: baris dan bagian kosong disembunyikan', (
      tester,
    ) async {
      await _pumpDetail(
        tester,
        (db, repository) => repository.addTask(title: 'Kuis'),
      );
      expect(find.text('Kuis'), findsOneWidget);
      expect(find.byType(AppBadge), findsNothing);
      expect(find.text('Sub-tugas'), findsNothing);
      expect(find.text('[CATATAN]'), findsNothing);
      expect(find.byType(AppIcon), findsNWidgets(2)); // panah + edit saja
    });

    testWidgets('edit: simpan perubahan tugas dan sub-tugas', (tester) async {
      final app = await _pumpDetail(tester, _seedFigma16);
      await tester.tap(find.bySemanticsLabel('Edit tugas'));
      await tester.pumpAndSettle();
      expect(find.text('Edit tugas'), findsOneWidget);
      expect(find.text(_title), findsOneWidget);

      Finder input(String label) => find.descendant(
        of: find.ancestor(
          of: find.text(label),
          matching: find.byType(AppInput),
        ),
        matching: find.byType(TextField),
      );
      final subtaskInput = find.byType(TextField).at(1);

      await tester.enterText(input('JUDUL TUGAS'), 'Laporan modul 5 final');
      await tester.tap(find.text('TINGGI'));
      await tester.pump();

      // Ganti nama sub-tugas ke-3, hapus ke-4, tambah satu.
      await tester.tap(find.text('Tulis analisis & kesimpulan'));
      await tester.pumpAndSettle();
      await tester.enterText(subtaskInput, 'Tulis analisis');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export PDF dan kumpulkan'));
      await tester.pumpAndSettle();
      await tester.enterText(subtaskInput, '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.tap(find.text('+ TAMBAH SUB-TUGAS'));
      await tester.pumpAndSettle();
      await tester.enterText(subtaskInput, 'Kumpulkan PDF');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      await tester.tap(find.text('SIMPAN PERUBAHAN'));
      await tester.pumpAndSettle();

      expect(
        app.router.state.matchedLocation,
        AppRoutes.tugasDetail(app.taskId),
      );
      expect(find.text('Laporan modul 5 final'), findsOneWidget);
      expect(find.text('PRIORITAS TINGGI'), findsOneWidget);

      final task = await app.task();
      expect(task.title, 'Laporan modul 5 final');
      expect(task.priority, TaskPriority.high);
      final subtasks = await app.subtasks();
      expect(subtasks.map((s) => (s.title, s.isDone)), [
        ('Kerjakan kode praktikum', true),
        ('Ambil screenshot hasil', true),
        ('Tulis analisis', false),
        ('Kumpulkan PDF', false),
      ]);
    });

    testWidgets('edit: Batal tidak menyimpan', (tester) async {
      final app = await _pumpDetail(tester, _seedFigma16);
      await tester.tap(find.bySemanticsLabel('Edit tugas'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Tidak jadi');
      await tester.tap(find.text('BATAL'));
      await tester.pumpAndSettle();

      expect(
        app.router.state.matchedLocation,
        AppRoutes.tugasDetail(app.taskId),
      );
      expect((await app.task()).title, _title);
    });

    testWidgets('edit: judul kosong menampilkan G2', (tester) async {
      final app = await _pumpDetail(tester, _seedFigma16);
      await tester.tap(find.bySemanticsLabel('Edit tugas'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '');
      await tester.tap(find.text('SIMPAN PERUBAHAN'));
      await tester.pumpAndSettle();

      expect(find.text('Judul wajib diisi'), findsOneWidget);
      expect((await app.task()).title, _title);
    });
  });
}
