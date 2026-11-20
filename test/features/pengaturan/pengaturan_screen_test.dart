import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/routes.dart';
import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/storage/key_value_store.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/features/auth/application/session_controller.dart';
import 'package:super_app/features/tugas/data/task_repository.dart';

import '../auth/auth_fakes.dart';

const _open = SessionState.unlocked(realUserId);

Future<void> _golden(WidgetTester tester, String name) => expectLater(
  find.byType(MaterialApp),
  matchesGoldenFile('goldens/$name.png'),
);

String _location(AuthHarness app) => app.router.state.matchedLocation;

Future<AuthHarness> _openAt(
  WidgetTester tester,
  String route, {
  Map<String, String>? store,
  Future<void> Function(AppDatabase db)? seed,
}) async {
  final auth = FakeAuth()
    ..currentUserId = realUserId
    ..currentEmail = 'bayu@email.com';
  final app = await pumpAuthApp(
    tester,
    session: _open,
    auth: auth,
    profileName: 'Bayu',
    store: store,
    seed: seed,
  );
  app.router.go(route);
  await tester.pumpAndSettle();
  return app;
}

void main() {
  testWidgets('06 Lainnya (MVP): ikon User membuka Pengaturan', (tester) async {
    final app = await _openAt(tester, AppRoutes.lainnya);
    expect(find.text('Lainnya'), findsWidgets);
    await tester.tap(find.byType(AppCircleButton));
    await tester.pumpAndSettle();
    expect(_location(app), AppRoutes.pengaturan);
  });

  testWidgets('06 Lainnya (MVP, F-66): 10 modul tampil sebagai Segera', (
    tester,
  ) async {
    final app = await _openAt(tester, AppRoutes.lainnya);
    final tiles = tester.widgetList<AppModuleTile>(find.byType(AppModuleTile));
    expect(tiles.map((t) => t.title), [
      'Fokus',
      'Kebiasaan',
      'Catatan',
      'Skripsi',
      'Belajar',
      'Proyek',
      'Statistik',
      'Kalender',
      'Nilai & IPK',
      'KKN',
    ]);
    expect(tiles.every((t) => t.state == AppModuleTileState.segera), isTrue);
    expect(find.text('SEGERA'), findsNWidgets(10));

    await tester.tap(find.text('Fokus'));
    await tester.pumpAndSettle();
    expect(_location(app), AppRoutes.lainnya);
  });

  testWidgets('14 Pengaturan (MVP): kartu akun dan grup Keamanan', (
    tester,
  ) async {
    await _openAt(tester, AppRoutes.pengaturan);
    expect(find.text('Masuk dengan email'), findsOneWidget);
    expect(find.text('NOTIFIKASI'), findsNothing);
    expect(find.text('Ekspor data'), findsNothing);
    await _golden(tester, 'pengaturan_14');
  });

  testWidgets('14: switch sidik jari menyimpan pilihan', (tester) async {
    final app = await _openAt(tester, AppRoutes.pengaturan);
    await tester.tap(find.byType(AppSwitch));
    await tester.pumpAndSettle();
    expect(await app.store.read(StoreKeys.biometricLock), 'mati');
  });

  testWidgets('P37 Akun dan P38 Keluar akun', (tester) async {
    await _openAt(tester, AppRoutes.pengaturan);
    await tester.tap(find.text('Bayu'));
    await tester.pumpAndSettle();
    expect(find.text('Bayu · masuk dengan email'), findsOneWidget);
    await _golden(tester, 'pengaturan_p37_akun');

    await tester.tap(find.text('KELUAR DARI AKUN'));
    await tester.pumpAndSettle();
    expect(find.text('Keluar dari akun?'), findsOneWidget);
    await _golden(tester, 'pengaturan_p38_keluar');

    await tester.tap(find.text('BATAL'));
    await tester.pumpAndSettle();
    expect(find.text('Keluar dari akun?'), findsNothing);
  });

  testWidgets('Keluar: data HP dihapus kalau sudah tersinkron, ke Intro', (
    tester,
  ) async {
    final app = await _openAt(
      tester,
      AppRoutes.pengaturan,
      store: {StoreKeys.lastUserId: realUserId, StoreKeys.pin: '123456'},
    );
    await app.container.read(sessionControllerProvider.notifier).signOut();
    await tester.pumpAndSettle();

    expect(app.auth.signOutCalls, 1);
    expect(app.session, const SessionState.signedOut());
    expect(_location(app), AppRoutes.intro);
    expect(await app.database.select(app.database.profiles).get(), isEmpty);
    expect(await app.store.read(StoreKeys.lastUserId), isNull);
    expect(await app.store.read(StoreKeys.pin), isNull);
  });

  testWidgets('Keluar: perubahan belum terkirim tidak dihapus', (tester) async {
    final app = await _openAt(
      tester,
      AppRoutes.pengaturan,
      seed: (db) =>
          TaskRepository(db, userId: realUserId).addTask(title: 'Kuis'),
    );
    await app.container.read(sessionControllerProvider.notifier).signOut();
    await tester.pumpAndSettle();

    expect(app.session, const SessionState.signedOut());
    expect(await app.database.select(app.database.tasks).get(), hasLength(1));
  });

  group('H05 Atur PIN cadangan', () {
    Future<void> type(WidgetTester tester, String pin) async {
      for (final d in pin.split('')) {
        await tester.tap(find.text(d));
      }
      await tester.pumpAndSettle();
    }

    testWidgets('langkah 1', (tester) async {
      await _openAt(tester, AppRoutes.pengaturanPin);
      await type(tester, '123');
      expect(find.text('Buat PIN cadangan'), findsOneWidget);
      await _golden(tester, 'pengaturan_h05_pin');
    });

    testWidgets('PIN diulang sama → tersimpan dan kembali', (tester) async {
      final app = await _openAt(tester, AppRoutes.pengaturan);
      await tester.tap(find.text('PIN cadangan'));
      await tester.pumpAndSettle();

      await type(tester, '123456');
      expect(find.text('Ulangi PIN cadangan'), findsOneWidget);
      await type(tester, '654321');
      expect(find.text('Ulangi PIN cadangan'), findsOneWidget);
      expect(await app.store.read(StoreKeys.pin), isNull);

      await type(tester, '123456');
      expect(await app.store.read(StoreKeys.pin), '123456');
      expect(_location(app), AppRoutes.pengaturan);
    });
  });
}
