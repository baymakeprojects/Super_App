import 'package:drift/drift.dart' show OrderingTerm, Value;
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
import 'package:super_app/features/tugas/application/task_form_controller.dart';

import '../../../helpers/svg.dart';
import '../../../helpers/test_database.dart';

/// "Sekarang" seperti status bar frame 15 dan P01–P03: Jumat 6 Nov 2026
/// 10.02.
final _now = DateTime(2026, 11, 6, 10, 2);

/// Ukuran frame HP Figma; status bar Android setinggi 32.
const Size _phone = Size(412, 917);
const double _statusBar = 32;

class _App {
  _App(this.router, this.container, this.database);

  final GoRouter router;
  final ProviderContainer container;
  final AppDatabase database;

  TaskFormController get form => container.read(taskFormProvider.notifier);
}

Future<_App> _pumpForm(
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

  // Rute anak: di bawahnya tetap ada 03 Tugas, jadi tutup = kembali ke 03.
  final router = buildAppRouter(initialLocation: AppRoutes.tugasBaru);
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

/// Semester 7 dan empat mata kuliah contoh P03.
Future<void> _seedCourses(AppDatabase db) async {
  await db
      .into(db.semesters)
      .insert(
        SemestersCompanion.insert(
          id: 's7',
          userId: devLocalUserId,
          name: 'Semester 7',
          isActive: const Value(true),
        ),
      );
  for (final (id, name, lecturer, weekday, time) in [
    ('c1', 'Manajemen Proyek TI', 'Pak Hendra', DateTime.monday, '10:00'),
    ('c2', 'Pemrograman Mobile', 'Bu Rina', DateTime.friday, '08:00'),
    ('c3', 'Metodologi Penelitian', 'Bu Sari', DateTime.friday, '13:00'),
    ('c4', 'Kecerdasan Buatan', 'Pak Andi', DateTime.friday, '10:00'),
  ]) {
    await db
        .into(db.courses)
        .insert(
          CoursesCompanion.insert(
            id: id,
            userId: devLocalUserId,
            semesterId: 's7',
            name: name,
            lecturer: Value(lecturer),
          ),
        );
    await db
        .into(db.classSessions)
        .insert(
          ClassSessionsCompanion.insert(
            id: 'k$id',
            userId: devLocalUserId,
            courseId: id,
            weekday: weekday,
            startsAt: time,
            endsAt: time,
          ),
        );
  }
}

Finder _input(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(AppInput)),
  matching: find.byType(TextField),
);

/// Kolom ketik sub-tugas: TextField kedua (setelah Judul, sebelum Catatan).
final Finder _subtaskInput = find.byType(TextField).at(1);

Finder _select(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(AppSelect));

Finder _chip(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(AppChip));

/// Isi contoh frame 15 (selain judul).
void _fillFigmaExtras(_App app) {
  app.form
    ..setCourse('c2', 'Pemrograman Mobile')
    ..addSubtask('Kerjakan kode praktikum')
    ..addSubtask('Tulis analisis & kesimpulan');
}

/// Isi contoh frame 15: judul diketik (kolom tetap fokus) dan isian lain.
Future<void> _fillFigma(WidgetTester tester, _App app) async {
  _fillFigmaExtras(app);
  await tester.enterText(_input('JUDUL TUGAS'), 'Laporan praktikum modul 5');
  await tester.pumpAndSettle();
}

Future<List<Task>> _tasks(AppDatabase db) => db.select(db.tasks).get();

void main() {
  group('golden sama dengan Figma', () {
    testWidgets('15 Tugas baru (30:1381)', (tester) async {
      final app = await _pumpForm(tester, seed: _seedCourses);
      await _fillFigma(tester, app);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/tugas_15_baru.png'),
      );
    });

    testWidgets('G2 judul kosong (137:4349)', (tester) async {
      final app = await _pumpForm(tester, seed: _seedCourses);
      _fillFigmaExtras(app);
      await tester.pumpAndSettle();
      await tester.tap(find.text('SIMPAN TUGAS'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/tugas_g2_judul_kosong.png'),
      );
    });

    testWidgets('P01 Pilih tanggal (50:326)', (tester) async {
      final app = await _pumpForm(tester, seed: _seedCourses);
      await _fillFigma(tester, app);
      await tester.tap(_select('TANGGAL'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/tugas_p01_tanggal.png'),
      );
    });

    testWidgets('P02 Pilih jam (50:393)', (tester) async {
      final app = await _pumpForm(tester, seed: _seedCourses);
      await _fillFigma(tester, app);
      await tester.tap(_select('JAM'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/tugas_p02_jam.png'),
      );
    });

    testWidgets('P03 Pilih mata kuliah (50:483)', (tester) async {
      final app = await _pumpForm(tester, seed: _seedCourses);
      await _fillFigma(tester, app);
      await tester.tap(_select('MATA KULIAH'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/tugas_p03_mata_kuliah.png'),
      );
    });
  });

  group('perilaku', () {
    testWidgets('isian awal: tanpa mata kuliah, hari ini 23.59, Sedang', (
      tester,
    ) async {
      await _pumpForm(tester);
      expect(find.text('Tanpa mata kuliah'), findsOneWidget);
      expect(find.text('Jum, 6 Nov'), findsOneWidget);
      expect(find.text('23.59'), findsOneWidget);
      final sedang = tester.widget<AppChip>(_chip('SEDANG'));
      expect(sedang.selected, isTrue);
      // Kartu "Ingatkan saya" Tahap 2 disembunyikan.
      expect(find.text('Ingatkan saya'), findsNothing);
    });

    testWidgets('G2: judul kosong tidak disimpan, isian lain tetap', (
      tester,
    ) async {
      final app = await _pumpForm(tester, seed: _seedCourses);
      _fillFigmaExtras(app);
      await tester.pumpAndSettle();

      // Spasi saja = kosong.
      await tester.enterText(_input('JUDUL TUGAS'), '   ');
      await tester.tap(find.text('SIMPAN TUGAS'));
      await tester.pumpAndSettle();

      expect(find.text('Judul wajib diisi'), findsOneWidget);
      expect(find.text('Pemrograman Mobile'), findsOneWidget);
      expect(find.text('Kerjakan kode praktikum'), findsOneWidget);
      expect(await _tasks(app.database), isEmpty);
      expect(app.router.state.matchedLocation, AppRoutes.tugasBaru);

      // Mulai mengetik = pesan hilang.
      await tester.enterText(_input('JUDUL TUGAS'), 'L');
      await tester.pumpAndSettle();
      expect(find.text('Judul wajib diisi'), findsNothing);
    });

    testWidgets('isi semua lewat pop-up lalu simpan: kembali ke 03', (
      tester,
    ) async {
      final app = await _pumpForm(tester, seed: _seedCourses);
      await tester.enterText(_input('JUDUL TUGAS'), 'Kuis bab 5');

      // P03: urutan kelas hari ini dulu, lalu Senin.
      await tester.tap(_select('MATA KULIAH'));
      await tester.pumpAndSettle();
      expect(find.text('Semester 7 · ketuk untuk memilih'), findsOneWidget);
      expect(find.text('Jumat · 10.00 · Pak Andi'), findsOneWidget);
      final titles = tester
          .widgetList<AppOptionItem>(find.byType(AppOptionItem))
          .map((o) => o.title);
      expect(titles, [
        'Pemrograman Mobile',
        'Kecerdasan Buatan',
        'Metodologi Penelitian',
        'Manajemen Proyek TI',
        'Tanpa mata kuliah',
      ]);
      await tester.tap(find.text('Kecerdasan Buatan'));
      await tester.pumpAndSettle();
      expect(find.text('Kecerdasan Buatan'), findsOneWidget);

      // P01: chip Senin depan lalu Pilih.
      await tester.tap(_select('TANGGAL'));
      await tester.pumpAndSettle();
      await tester.tap(_chip('SENIN DEPAN'));
      await tester.pump();
      await tester.tap(find.text('PILIH'));
      await tester.pumpAndSettle();
      expect(find.text('Sen, 9 Nov'), findsOneWidget);

      // P02: subjudul menyebut tanggal; chip 12.00 lalu Pilih.
      await tester.tap(_select('JAM'));
      await tester.pumpAndSettle();
      expect(find.text('Jam deadline · Sen, 9 Nov'), findsOneWidget);
      await tester.tap(_chip('12.00'));
      await tester.pump();
      await tester.tap(find.text('PILIH'));
      await tester.pumpAndSettle();
      expect(find.text('12.00'), findsOneWidget);

      await tester.tap(_chip('TINGGI'));
      await tester.pump();

      // Sub-tugas: dua kali Enter berturut-turut, lalu Enter kosong menutup.
      await tester.tap(find.text('+ TAMBAH SUB-TUGAS'));
      await tester.pumpAndSettle();
      await tester.enterText(_subtaskInput, 'Baca bab 5');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.enterText(_subtaskInput, 'Latihan soal');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('+ TAMBAH SUB-TUGAS'), findsOneWidget);

      await tester.enterText(_input('CATATAN'), 'Bab 5 saja');

      await tester.tap(find.text('SIMPAN TUGAS'));
      await tester.pumpAndSettle();

      expect(app.router.state.matchedLocation, AppRoutes.tugas);
      expect(find.text('Kuis bab 5'), findsOneWidget);

      final task = (await _tasks(app.database)).single;
      expect(task.title, 'Kuis bab 5');
      expect(task.courseId, 'c4');
      expect(task.dueAt, DateTime(2026, 11, 9, 12));
      expect(task.priority, TaskPriority.high);
      expect(task.notes, 'Bab 5 saja');
      final subtasks = await (app.database.select(
        app.database.subtasks,
      )..orderBy([(s) => OrderingTerm(expression: s.position)])).get();
      expect(subtasks.map((s) => s.title), ['Baca bab 5', 'Latihan soal']);
    });

    testWidgets('Tanpa tanggal: jam jadi "—" dan deadline kosong', (
      tester,
    ) async {
      final app = await _pumpForm(tester);
      await tester.enterText(_input('JUDUL TUGAS'), 'Skripsi bab 1');

      await tester.tap(_select('TANGGAL'));
      await tester.pumpAndSettle();
      await tester.tap(_chip('TANPA TANGGAL'));
      await tester.pump();
      await tester.tap(find.text('PILIH'));
      await tester.pumpAndSettle();

      expect(find.text('Tanpa tanggal'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      // Jam tidak bisa dipilih.
      await tester.tap(_select('JAM'));
      await tester.pumpAndSettle();
      expect(find.text('Pilih jam'), findsNothing);

      await tester.tap(find.text('SIMPAN TUGAS'));
      await tester.pumpAndSettle();
      final task = (await _tasks(app.database)).single;
      expect(task.dueAt, isNull);
      expect(task.courseId, isNull);
      expect(task.notes, isNull);
    });

    testWidgets('Batal di pop-up tidak mengubah isian', (tester) async {
      await _pumpForm(tester);
      await tester.tap(_select('TANGGAL'));
      await tester.pumpAndSettle();
      await tester.tap(_chip('BESOK'));
      await tester.pump();
      await tester.tap(find.text('BATAL'));
      await tester.pumpAndSettle();
      expect(find.text('Jum, 6 Nov'), findsOneWidget);
    });

    testWidgets('ketuk sub-tugas untuk mengubah; dikosongkan = dihapus', (
      tester,
    ) async {
      final app = await _pumpForm(tester);
      _fillFigmaExtras(app);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kerjakan kode praktikum'));
      await tester.pumpAndSettle();
      await tester.enterText(_subtaskInput, 'Kode modul 5');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(app.container.read(taskFormProvider).subtasks, [
        'Kode modul 5',
        'Tulis analisis & kesimpulan',
      ]);

      await tester.tap(find.text('Tulis analisis & kesimpulan'));
      await tester.pumpAndSettle();
      await tester.enterText(_subtaskInput, '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(app.container.read(taskFormProvider).subtasks, ['Kode modul 5']);
    });

    testWidgets('Close menutup tanpa menyimpan', (tester) async {
      final app = await _pumpForm(tester);
      await tester.enterText(_input('JUDUL TUGAS'), 'Tidak jadi');
      await tester.tap(find.bySemanticsLabel('Tutup'));
      await tester.pumpAndSettle();
      expect(app.router.state.matchedLocation, AppRoutes.tugas);
      expect(await _tasks(app.database), isEmpty);
    });

    testWidgets('+ Tambah mata kuliah membuka Jadwal baru', (tester) async {
      await _pumpForm(tester);
      await tester.tap(_select('MATA KULIAH'));
      await tester.pumpAndSettle();
      // Tanpa semester aktif dan tanpa mata kuliah.
      expect(find.text('Ketuk untuk memilih'), findsOneWidget);
      expect(find.byType(AppOptionItem), findsOneWidget);

      await tester.tap(find.text('+ TAMBAH MATA KULIAH'));
      await tester.pumpAndSettle();
      expect(find.text('Jadwal baru'), findsOneWidget);
    });
  });
}
