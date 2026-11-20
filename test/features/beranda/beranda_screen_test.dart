import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
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
import 'package:super_app/core/sync/sync_controller.dart';
import 'package:super_app/core/sync/sync_engine.dart';
import 'package:super_app/core/sync/sync_status.dart';
import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/features/auth/application/current_user_id_provider.dart';
import 'package:super_app/features/beranda/application/beranda_view.dart';
import 'package:super_app/features/keuangan/application/keuangan_providers.dart';
import 'package:super_app/features/keuangan/data/finance_repository.dart';
import 'package:super_app/features/kuliah/data/course_repository.dart';
import 'package:super_app/features/kuliah/data/semester_repository.dart';
import 'package:super_app/features/tugas/data/task_repository.dart';

import '../../helpers/svg.dart';
import '../../helpers/test_database.dart';

/// "Sekarang" seperti status bar frame 02: Jumat 6 Nov 2026 07.35.
final _now = DateTime(2026, 11, 6, 7, 35);

const Size _phone = Size(412, 917);
const double _statusBar = 32;

/// Status sinkron tetap untuk uji banner; Coba lagi dihitung.
class _FakeSync extends SyncController {
  _FakeSync(this.initial);

  final SyncState initial;
  int retries = 0;

  @override
  SyncState build() => initial;

  @override
  Future<SyncResult?> syncNow() async {
    retries++;
    state = const SyncState(phase: SyncPhase.synced);
    return null;
  }
}

Future<GoRouter> _pump(
  WidgetTester tester, {
  Future<void> Function(AppDatabase db)? seed,
  _FakeSync? sync,
  bool loading = false,
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

  final router = buildAppRouter();
  addTearDown(router.dispose);
  final container = ProviderContainer(
    overrides: [
      appRouterProvider.overrideWithValue(router),
      appDatabaseProvider.overrideWithValue(database),
      clockProvider.overrideWithValue(() => _now),
      // Dompet tidak pernah selesai dimuat → E7.
      if (loading)
        walletsProvider.overrideWith(
          (ref) => StreamController<List<WalletBalance>>().stream,
        ),
      if (sync != null) ...[
        syncControllerProvider.overrideWith(() => sync),
        // Seperti frame: 3 perubahan menunggu.
        pendingChangesProvider.overrideWith((ref) => Stream.value(3)),
      ],
    ],
  );
  addTearDown(container.dispose);

  await precacheAppIcons(tester);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const SuperApp()),
  );
  if (loading) {
    // Kerangka memuat beranimasi terus; cukup tunggu pudar pembukaan app.
    await tester.pump();
    await tester.pump(AppMotion.launch);
  } else {
    await tester.pumpAndSettle();
  }
  return router;
}

/// Isi contoh frame 02.
/// E1 di Figma: nama Bayu, hanya jadwal yang terisi (1 dari 3).
Future<void> _seedE1(AppDatabase db) async {
  await db
      .into(db.profiles)
      .insert(
        ProfilesCompanion.insert(
          id: 'p1',
          userId: devLocalUserId,
          name: const Value('Bayu'),
        ),
      );
  final semesterId = await SemesterRepository(
    db,
    userId: devLocalUserId,
  ).addSemester(name: 'Semester 7', startsOn: DateTime(2026, 9), active: true);
  await CourseRepository(db, userId: devLocalUserId).addCourse(
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
}

Future<void> _seedFigma(AppDatabase db) async {
  await db
      .into(db.profiles)
      .insert(
        ProfilesCompanion.insert(
          id: 'p1',
          userId: devLocalUserId,
          name: const Value('Bayu'),
        ),
      );

  final semesterId = await SemesterRepository(
    db,
    userId: devLocalUserId,
  ).addSemester(name: 'Semester 7', startsOn: DateTime(2026, 9), active: true);
  final courses = CourseRepository(db, userId: devLocalUserId);
  CourseInput course(
    String name,
    String room,
    String lecturer,
    String start,
    String end,
  ) => (
    name: name,
    lecturer: lecturer,
    room: room,
    credits: 3,
    weekday: DateTime.friday,
    startsAt: start,
    endsAt: end,
  );
  final mobile = await courses.addCourse(
    semesterId: semesterId,
    input: course(
      'Pemrograman Mobile',
      'Ruang 301',
      'Bu Rina',
      '08:00',
      '09:40',
    ),
  );
  final metopen = await courses.addCourse(
    semesterId: semesterId,
    input: course(
      'Metodologi Penelitian',
      'Ruang 105',
      'Bu Sari',
      '13:00',
      '14:40',
    ),
  );

  final tasks = TaskRepository(db, userId: devLocalUserId, now: () => _now);
  await tasks.addTask(
    title: 'Revisi proposal penelitian',
    courseId: metopen,
    dueAt: DateTime(2026, 11, 5, 23, 59),
  );
  await tasks.addTask(
    title: 'Laporan praktikum modul 5',
    courseId: mobile,
    dueAt: DateTime(2026, 11, 6, 23, 59),
  );
  for (final (title, due) in [
    ('Kuis bab 4', DateTime(2026, 11, 7, 13)),
    ('Presentasi kelompok', DateTime(2026, 11, 9, 10)),
    ('Skripsi bab 2', DateTime(2026, 11, 20, 9)),
  ]) {
    await tasks.addTask(title: title, dueAt: due);
  }

  // Saldo Rp1,25jt; minggu ini (mulai Senin 2 Nov) keluar 340rb.
  final finance = FinanceRepository(db, userId: devLocalUserId);
  await finance.ensureDefaultCategories();
  final makan = (await finance.getCategories(MoneyKind.expense)).first;
  final tunai = await finance.addWallet(
    name: 'Tunai',
    kind: WalletKind.cash,
    openingBalance: 90000,
  );
  final bank = await finance.addWallet(name: 'Bank', kind: WalletKind.bank);
  TransactionInput tx(
    String wallet,
    MoneyKind kind,
    int amount,
    DateTime at, {
    String? notes,
    String? categoryId,
  }) => (
    walletId: wallet,
    categoryId: categoryId,
    kind: kind,
    amount: amount,
    notes: notes,
    occurredAt: at,
  );
  await finance.addTransaction(
    tx(
      bank,
      MoneyKind.income,
      1500000,
      DateTime(2026, 11, 1, 8),
      notes: 'Uang saku',
    ),
  );
  await finance.addTransaction(
    tx(
      bank,
      MoneyKind.expense,
      325000,
      DateTime(2026, 11, 2, 9),
      notes: 'Bayar kos',
    ),
  );
  await finance.addTransaction(
    tx(
      tunai,
      MoneyKind.expense,
      15000,
      DateTime(2026, 11, 6, 7, 10),
      notes: 'Sarapan',
      categoryId: makan.id,
    ),
  );
}

const SyncState _offline = SyncState(
  phase: SyncPhase.failed,
  lastError: SocketException('Failed host lookup'),
  failures: 1,
);

final SyncState _serverDown = SyncState(
  phase: SyncPhase.failed,
  lastError: Exception('503 Service Unavailable'),
  failures: syncFailedBannerAfter,
);

void main() {
  testWidgets('golden: 02 Beranda (13:14)', (tester) async {
    await _pump(tester, seed: _seedFigma);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/beranda_02.png'),
    );
  });

  testWidgets('E7 Memuat (Figma 68:2289)', (tester) async {
    await _pump(tester, seed: _seedE1, loading: true);
    expect(find.byType(AppSkeletonList), findsOneWidget);
    expect(find.text('Siapkan Super App kamu'), findsNothing);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/beranda_e7_memuat.png'),
    );
  });

  testWidgets('E1 Beranda kosong (Figma 67:1902)', (tester) async {
    await _pump(tester, seed: _seedE1);
    expect(find.text('[MULAI] 1 DARI 3 SELESAI'), findsOneWidget);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/beranda_e1_kosong.png'),
    );
  });

  testWidgets('golden: E5 Beranda offline (68:2132)', (tester) async {
    await _pump(tester, seed: _seedFigma, sync: _FakeSync(_offline));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/beranda_e5_offline.png'),
    );
  });

  testWidgets('golden: G8 Sinkron gagal (137:4901)', (tester) async {
    await _pump(tester, seed: _seedFigma, sync: _FakeSync(_serverDown));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/beranda_g8_sinkron_gagal.png'),
    );
  });

  group('banner sinkron', () {
    testWidgets('E5: Coba lagi menyinkron; banner hilang setelah berhasil', (
      tester,
    ) async {
      final sync = _FakeSync(_offline);
      await _pump(tester, seed: _seedFigma, sync: sync);
      expect(find.text('Kamu sedang offline'), findsOneWidget);
      expect(
        find.text('3 perubahan tersimpan di HP, disinkron saat online'),
        findsOneWidget,
      );

      await tester.tap(find.text('COBA LAGI'));
      await tester.pumpAndSettle();
      expect(sync.retries, 1);
      expect(find.byType(AppBanner), findsNothing);
    });

    testWidgets('G8: teks dari frame, Coba lagi menyinkron', (tester) async {
      final sync = _FakeSync(_serverDown);
      await _pump(tester, seed: _seedFigma, sync: sync);
      expect(find.text('Sinkron gagal'), findsOneWidget);
      expect(
        find.text('3 perubahan belum terkirim. Server sedang bermasalah.'),
        findsOneWidget,
      );
      await tester.tap(find.text('COBA LAGI'));
      await tester.pumpAndSettle();
      expect(sync.retries, 1);
    });

    testWidgets('sinkron baik: tanpa banner', (tester) async {
      await _pump(
        tester,
        seed: _seedFigma,
        sync: _FakeSync(const SyncState(phase: SyncPhase.synced)),
      );
      expect(find.byType(AppBanner), findsNothing);
    });
  });

  group('perilaku', () {
    testWidgets('isi Beranda dari data asli', (tester) async {
      await _pump(tester, seed: _seedFigma);
      expect(find.text('JUMAT, 6 NOVEMBER'), findsOneWidget);
      expect(find.text('Halo, Bayu'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('KELAS BERIKUTNYA · 25 MENIT LAGI'), findsOneWidget);
      expect(find.text('08.00–09.40 · Ruang 301 · Bu Rina'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('2 jatuh tempo hari ini'), findsOneWidget);
      expect(find.text('Rp1,25jt'), findsOneWidget);
      expect(find.text('−Rp340rb minggu ini'), findsOneWidget);
      expect(find.text('Revisi proposal penelitian'), findsOneWidget);
      expect(find.text('Kuis bab 4'), findsNothing); // bukan hari ini
      expect(find.text('Sarapan'), findsOneWidget);
      expect(find.text('Uang saku'), findsNothing); // hanya 2 terbaru
    });

    testWidgets('Lihat semua pindah ke tab; kartu kelas ke detail', (
      tester,
    ) async {
      final router = await _pump(tester, seed: _seedFigma);
      await tester.tap(find.text('LIHAT SEMUA →').first);
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, AppRoutes.tugas);

      router.go(AppRoutes.beranda);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pemrograman Mobile'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, startsWith('/kuliah/'));
    });

    testWidgets(
      'tanpa data dan nama: Halo, E1 checklist 0 dari 3, tanpa Stat Card',
      (tester) async {
        await _pump(tester);
        expect(find.text('Halo'), findsOneWidget);
        expect(find.text('[MULAI] 0 DARI 3 SELESAI'), findsOneWidget);
        expect(find.byType(AppStatCard), findsNothing);
        expect(find.text('Belum ada tugas'), findsOneWidget);
        expect(find.text('Transaksi terakhir'), findsNothing);
        expect(find.textContaining('KELAS BERIKUTNYA'), findsNothing);
      },
    );

    testWidgets('E1: checklist membuka Tugas baru, hilang setelah selesai', (
      tester,
    ) async {
      final router = await _pump(tester, seed: _seedE1);
      await tester.tap(find.text('Tambah tugas pertama'));
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, AppRoutes.tugasBaru);
    });

    testWidgets('E1 hilang setelah ketiga langkah selesai', (tester) async {
      await _pump(tester, seed: _seedFigma);
      expect(find.text('Siapkan Super App kamu'), findsNothing);
      expect(find.byType(AppStatCard), findsNWidgets(2));
    });
  });

  group('aturan', () {
    test('hitung mundur', () {
      expect(countdownLabel(25), '25 menit lagi');
      expect(countdownLabel(60), '1 jam lagi');
      expect(countdownLabel(85), '1 jam 25 menit lagi');
    });

    test('awal minggu Senin; huruf awal nama', () {
      expect(weekStartOf(_now), DateTime(2026, 11, 2));
      expect(weekStartOf(DateTime(2026, 11, 8, 23)), DateTime(2026, 11, 2));
      expect(initialOf(' bayu'), 'B');
      expect(initialOf(''), isNull);
    });
  });
}
