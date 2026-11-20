import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/routes.dart';
import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/storage/key_value_store.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/features/auth/application/session_controller.dart';
import 'package:super_app/features/beranda/presentation/beranda_screen.dart';
import 'package:super_app/features/keuangan/data/finance_repository.dart';
import 'package:super_app/features/kuliah/data/course_repository.dart';
import 'package:super_app/features/kuliah/data/semester_repository.dart';

import '../auth/auth_fakes.dart';

const _firstLogin = SessionState.unlocked(realUserId, needsSetup: true);

Future<void> _golden(WidgetTester tester, String name) => expectLater(
  find.byType(MaterialApp),
  matchesGoldenFile('goldens/$name.png'),
);

String _location(AuthHarness app) => app.router.state.matchedLocation;

/// Semester 7 dengan tiga mata kuliah Jumat, seperti frame 01a.
Future<void> _seedSchedule(AppDatabase db) async {
  final semesterId = await SemesterRepository(
    db,
    userId: realUserId,
  ).addSemester(name: 'Semester 7', startsOn: DateTime(2026, 9), active: true);
  final courses = CourseRepository(db, userId: realUserId);
  for (final (name, room, start, end) in [
    ('Pemrograman Mobile', 'Ruang 301', '08:00', '09:40'),
    ('Kecerdasan Buatan', 'Ruang 204', '10:00', '11:40'),
    ('Metodologi Penelitian', 'Ruang 105', '13:00', '14:40'),
  ]) {
    await courses.addCourse(
      semesterId: semesterId,
      input: (
        name: name,
        lecturer: null,
        room: room,
        credits: 3,
        weekday: DateTime.friday,
        startsAt: start,
        endsAt: end,
      ),
    );
  }
}

Future<AuthHarness> _open(
  WidgetTester tester,
  String route, {
  Future<void> Function(AppDatabase db)? seed,
}) async {
  final app = await pumpAuthApp(tester, session: _firstLogin, seed: seed);
  app.router.go(route);
  await tester.pumpAndSettle();
  return app;
}

void main() {
  testWidgets('login pertama membuka 01a, login berikutnya ke Beranda', (
    tester,
  ) async {
    final app = await pumpAuthApp(
      tester,
      session: const SessionState.signedOut(),
    );
    await app.container
        .read(sessionControllerProvider.notifier)
        .signedIn(realUserId);
    await tester.pumpAndSettle();
    expect(_location(app), AppRoutes.setupJadwal);

    await tester.tap(find.text('LEWATI'));
    await tester.pumpAndSettle();
    expect(find.byType(BerandaScreen), findsOneWidget);
    expect(await app.store.read(StoreKeys.setupDone(realUserId)), isNotNull);

    // Masuk lagi (misalnya setelah sesi berakhir): setup tidak diulang.
    await app.container
        .read(sessionControllerProvider.notifier)
        .signedIn(realUserId);
    expect(app.session.needsSetup, isFalse);
  });

  testWidgets('01a Jadwal semester', (tester) async {
    final app = await _open(tester, AppRoutes.setupJadwal, seed: _seedSchedule);
    expect(find.text('MATA KULIAH · 3'), findsOneWidget);
    await _golden(tester, 'setup_01a_jadwal');

    await tester.tap(find.text('+ TAMBAH MATA KULIAH'));
    await tester.pumpAndSettle();
    expect(_location(app), AppRoutes.kuliahJadwalBaru);
  });

  testWidgets('01b Dompet & saldo awal membuat tiga dompet', (tester) async {
    final app = await _open(tester, AppRoutes.setupDompet);
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '150000');
    await tester.enterText(fields.at(1), '900000');
    await tester.enterText(fields.at(2), '200000');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(find.text('Rp1.250.000'), findsOneWidget);
    await _golden(tester, 'setup_01b_dompet');

    await tester.tap(find.text('LANJUT →'));
    await tester.pumpAndSettle();
    expect(_location(app), AppRoutes.setupKeamanan);
    final wallets = await FinanceRepository(
      app.database,
      userId: realUserId,
    ).getWallets();
    expect(
      [for (final w in wallets) (w.name, w.openingBalance)],
      [('Tunai', 150000), ('Bank', 900000), ('E-wallet', 200000)],
    );
  });

  testWidgets('01c Keamanan: switch sidik jari, Selesai ke Beranda', (
    tester,
  ) async {
    final app = await _open(tester, AppRoutes.setupKeamanan);
    expect(find.text('LEWATI'), findsNothing);
    expect(find.text('Pengingat kelas'), findsNothing);
    await _golden(tester, 'setup_01c_keamanan');

    await tester.tap(find.byType(AppSwitch));
    await tester.pumpAndSettle();
    expect(await app.store.read(StoreKeys.biometricLock), 'mati');

    await tester.tap(find.text('SELESAI, KE BERANDA →'));
    await tester.pumpAndSettle();
    expect(find.byType(BerandaScreen), findsOneWidget);
    expect(app.session.needsSetup, isFalse);
  });

  testWidgets('E3 "Atau isi lewat setup awal" membuka 01b', (tester) async {
    final app = await pumpAuthApp(
      tester,
      session: const SessionState.unlocked(realUserId),
    );
    app.router.go(AppRoutes.keuangan);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ATAU ISI LEWAT SETUP AWAL'));
    await tester.pumpAndSettle();
    expect(_location(app), AppRoutes.setupDompet);
  });

  test('kunci sidik jari mati: app terbuka tanpa 01', () async {
    final auth = FakeAuth()..currentUserId = realUserId;
    final store = MemoryKeyValueStore();
    expect(
      await readInitialSession(auth: auth, store: store),
      const SessionState.locked(realUserId),
    );
    await store.write(StoreKeys.biometricLock, 'mati');
    expect(
      await readInitialSession(auth: auth, store: store),
      const SessionState.unlocked(realUserId),
    );
  });
}
