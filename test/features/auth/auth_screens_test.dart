import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/routes.dart';
import 'package:super_app/core/storage/key_value_store.dart';
import 'package:super_app/features/auth/application/session_controller.dart';
import 'package:super_app/features/auth/data/device_lock.dart';

import 'auth_fakes.dart';

const _signedOut = SessionState.signedOut();
const _locked = SessionState.locked(realUserId);

Future<void> _golden(WidgetTester tester, String name) => expectLater(
  find.byType(MaterialApp),
  matchesGoldenFile('goldens/$name.png'),
);

/// Lokasi layar teratas (juga halaman yang dibuka dengan push).
String _location(AuthHarness app) => app.router.state.matchedLocation;

/// Buka 00e, ketik [email], ketuk tombol.
Future<void> _submitEmail(WidgetTester tester, String email) async {
  await tester.enterText(find.byType(TextField), email);
  await tester.tap(find.text('KIRIM KODE →'));
  await tester.pump();
}

/// Dari 00e sampai 00f dengan email bayu@email.com.
Future<AuthHarness> _openCode(WidgetTester tester, {FakeAuth? auth}) async {
  final app = await pumpAuthApp(tester, session: _signedOut, auth: auth);
  app.router.go(AppRoutes.masuk);
  await tester.pumpAndSettle();
  await _submitEmail(tester, 'bayu@email.com');
  // Transisi halaman; hitung mundur membuat pumpAndSettle tidak selesai.
  await tester.pump(const Duration(milliseconds: 500));
  return app;
}

/// Majukan jam [seconds] detik setelah kode terkirim.
Future<void> _after(WidgetTester tester, AuthHarness app, int seconds) async {
  app.clock.now = DateTime(2026, 11, 20, 7, 2).add(Duration(seconds: seconds));
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _typeCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(TextField), code);
  await tester.pump();
}

void main() {
  group('alur saat app dibuka', () {
    testWidgets('belum login → Intro 00a–00d, Lanjut lalu Mulai sekarang', (
      tester,
    ) async {
      final app = await pumpAuthApp(tester, session: _signedOut);
      expect(_location(app), AppRoutes.intro);
      expect(find.text('Semua urusan kuliah\ndi satu app'), findsOneWidget);
      await _golden(tester, 'auth_00a_intro');

      await tester.tap(find.text('LANJUT →'));
      await tester.pumpAndSettle();
      expect(find.text('Jadwal dan deadline\ntidak kelewat'), findsOneWidget);
      await _golden(tester, 'auth_00b_intro');

      await tester.tap(find.text('LANJUT →'));
      await tester.pumpAndSettle();
      expect(find.text('Uang bulanan\ntetap terkendali'), findsOneWidget);
      await _golden(tester, 'auth_00c_intro');

      await tester.tap(find.text('LANJUT →'));
      await tester.pumpAndSettle();
      expect(find.text('LEWATI'), findsNothing);
      await _golden(tester, 'auth_00d_intro');

      await tester.tap(find.text('MULAI SEKARANG →'));
      await tester.pumpAndSettle();
      expect(_location(app), AppRoutes.masuk);
    });

    testWidgets('Intro: geser ke halaman berikutnya', (tester) async {
      await pumpAuthApp(tester, session: _signedOut);
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Jadwal dan deadline\ntidak kelewat'), findsOneWidget);
    });

    testWidgets('Intro: Lewati membuka Masuk dengan email', (tester) async {
      final app = await pumpAuthApp(tester, session: _signedOut);
      await tester.tap(find.text('LEWATI'));
      await tester.pumpAndSettle();
      expect(_location(app), AppRoutes.masuk);
    });

    testWidgets('sudah login → 01 Kunci, rute lain dialihkan', (tester) async {
      final app = await pumpAuthApp(tester, session: _locked);
      expect(_location(app), AppRoutes.kunci);
      app.router.go(AppRoutes.tugas);
      await tester.pumpAndSettle();
      expect(_location(app), AppRoutes.kunci);
    });
  });

  group('00e Masuk dengan email', () {
    testWidgets('default', (tester) async {
      // Kursor selalu tampil (seperti di Figma), tidak bergantung waktu kedip.
      EditableText.debugDeterministicCursor = true;
      addTearDown(() => EditableText.debugDeterministicCursor = false);
      final app = await pumpAuthApp(tester, session: _signedOut);
      app.router.go(AppRoutes.masuk);
      await tester.pumpAndSettle();
      await _golden(tester, 'auth_00e_masuk');
    });

    testWidgets('email tidak valid', (tester) async {
      final app = await pumpAuthApp(tester, session: _signedOut);
      app.router.go(AppRoutes.masuk);
      await tester.pumpAndSettle();
      await _submitEmail(tester, 'bayu@email');
      await tester.pumpAndSettle();

      expect(
        find.text('Format email belum benar. Contoh: nama@email.com'),
        findsOneWidget,
      );
      expect(app.auth.sentTo, isEmpty);
      await _golden(tester, 'auth_00e_email_tidak_valid');
    });

    testWidgets('mengirim kode', (tester) async {
      final auth = FakeAuth()..hold = Completer<void>();
      final app = await pumpAuthApp(tester, session: _signedOut, auth: auth);
      app.router.go(AppRoutes.masuk);
      await tester.pumpAndSettle();
      await _submitEmail(tester, 'bayu@email.com');
      await tester.pumpAndSettle();

      expect(find.text('MENGIRIM KODE…'), findsOneWidget);
      await _golden(tester, 'auth_00e_mengirim');
      auth.hold!.complete();
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('gagal kirim kode, lalu Coba lagi berhasil', (tester) async {
      final auth = FakeAuth()
        ..sendError = const SocketException('Failed host lookup');
      final app = await pumpAuthApp(tester, session: _signedOut, auth: auth);
      app.router.go(AppRoutes.masuk);
      await tester.pumpAndSettle();
      await _submitEmail(tester, 'bayu@email.com');
      await tester.pumpAndSettle();

      expect(find.text('Kode belum terkirim'), findsOneWidget);
      await _golden(tester, 'auth_00e_gagal_kirim');

      auth.sendError = null;
      await tester.tap(find.text('COBA LAGI →'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(_location(app), AppRoutes.masukKode);
    });
  });

  group('00f Masukkan kode', () {
    testWidgets('default: hitung mundur dan kotak aktif', (tester) async {
      final app = await _openCode(tester);
      expect(_location(app), AppRoutes.masukKode);
      expect(
        find.text(
          'Kode 6 digit sudah dikirim ke bayu@email.com. Berlaku 10 menit.',
        ),
        findsOneWidget,
      );
      await _typeCode(tester, '482');
      await _after(tester, app, 18);
      expect(find.text('KIRIM ULANG DALAM 00.42'), findsOneWidget);
      await _golden(tester, 'auth_00f_kode');
    });

    testWidgets('kode salah', (tester) async {
      final app = await _openCode(tester);
      await _typeCode(tester, '482190');
      await _after(tester, app, 42);
      await tester.tap(find.text('MASUK →'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Kode salah. Periksa lagi kode di email terbaru.'),
        findsOneWidget,
      );
      expect(app.session, _signedOut);
      await _golden(tester, 'auth_00f_kode_salah');
    });

    testWidgets('kode kedaluwarsa, Kirim ulang kode mengirim lagi', (
      tester,
    ) async {
      final app = await _openCode(tester);
      await _typeCode(tester, '482190');
      await _after(tester, app, 11 * 60);
      await tester.tap(find.text('MASUK →'));
      await tester.pump();
      await tester.pump();

      expect(
        find.text('Kode sudah kedaluwarsa. Minta kode baru.'),
        findsOneWidget,
      );
      await _golden(tester, 'auth_00f_kode_kedaluwarsa');

      await tester.tap(find.text('KIRIM ULANG KODE'));
      await tester.pump();
      expect(app.auth.sentTo, ['bayu@email.com', 'bayu@email.com']);
      expect(find.textContaining('kedaluwarsa'), findsNothing);
    });

    testWidgets('memeriksa kode, lalu login pertama ke Setup awal', (
      tester,
    ) async {
      final auth = FakeAuth();
      final app = await _openCode(tester, auth: auth);
      await _typeCode(tester, validCode);
      await _after(tester, app, 29);
      auth.hold = Completer<void>();
      await tester.tap(find.text('MASUK →'));
      await tester.pump();

      expect(find.text('MEMERIKSA KODE…'), findsOneWidget);
      await _golden(tester, 'auth_00f_memeriksa');

      auth.hold!.complete();
      await tester.pumpAndSettle();
      expect(
        app.session,
        const SessionState.unlocked(realUserId, needsSetup: true),
      );
      expect(await app.store.read(StoreKeys.lastUserId), realUserId);
      expect(_location(app), AppRoutes.setupJadwal);
    });

    testWidgets('Ganti email kembali ke 00e', (tester) async {
      final app = await _openCode(tester);
      await tester.tap(find.text('GANTI EMAIL'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(_location(app), AppRoutes.masuk);
    });
  });

  group('01 Kunci sidik jari', () {
    testWidgets('tampil dan langsung meminta sidik jari', (tester) async {
      final app = await pumpAuthApp(
        tester,
        session: _locked,
        profileName: 'Bayu',
      );
      expect(app.lock.biometricCalls, 1);
      await _golden(tester, 'auth_01_kunci');
    });

    testWidgets('sidik jari cocok → Beranda', (tester) async {
      final app = await pumpAuthApp(
        tester,
        session: _locked,
        lock: FakeDeviceLock(biometric: [UnlockResult.success]),
      );
      expect(app.session.status, SessionStatus.unlocked);
      expect(_location(app), AppRoutes.beranda);
    });

    testWidgets('gagal 3 kali → H06 kalau PIN sudah diatur', (tester) async {
      final app = await pumpAuthApp(
        tester,
        session: _locked,
        store: {StoreKeys.pin: '123456'},
        lock: FakeDeviceLock(
          biometric: [UnlockResult.failed, UnlockResult.failed],
        ),
      );
      // Percobaan 2 dan 3 lewat ketukan sensor.
      await tester.tap(find.text('MENUNGGU SIDIK JARI…'));
      await tester.pumpAndSettle();
      expect(_location(app), AppRoutes.kunci);
      app.lock.biometric.add(UnlockResult.failed);
      await tester.tap(find.text('MENUNGGU SIDIK JARI…'));
      await tester.pumpAndSettle();
      expect(_location(app), AppRoutes.kunciPin);
    });

    testWidgets('Pakai PIN perangkat tanpa PIN app → kunci layar HP', (
      tester,
    ) async {
      final app = await pumpAuthApp(
        tester,
        session: _locked,
        lock: FakeDeviceLock(credential: UnlockResult.success),
      );
      await tester.tap(find.text('PAKAI PIN PERANGKAT'));
      await tester.pumpAndSettle();
      expect(app.lock.credentialCalls, 1);
      expect(_location(app), AppRoutes.beranda);
    });
  });

  group('H06 Masukkan PIN', () {
    Future<AuthHarness> openPin(WidgetTester tester) async {
      final app = await pumpAuthApp(
        tester,
        session: _locked,
        profileName: 'Bayu',
        store: {StoreKeys.pin: '123456'},
      );
      await tester.tap(find.text('PAKAI PIN PERANGKAT'));
      await tester.pumpAndSettle();
      return app;
    }

    testWidgets('tampil dengan titik terisi', (tester) async {
      await openPin(tester);
      await tester.tap(find.text('1'));
      await tester.tap(find.text('2'));
      await tester.pump();
      await _golden(tester, 'auth_h06_pin');
    });

    testWidgets('PIN salah dikosongkan, PIN benar membuka app', (tester) async {
      final app = await openPin(tester);
      for (final d in '111111'.split('')) {
        await tester.tap(find.text(d));
      }
      await tester.pumpAndSettle();
      expect(app.session.status, SessionStatus.locked);

      for (final d in '123456'.split('')) {
        await tester.tap(find.text(d));
      }
      await tester.pumpAndSettle();
      expect(app.session.status, SessionStatus.unlocked);
      expect(_location(app), AppRoutes.beranda);
    });

    testWidgets('Lupa PIN membuka 00e', (tester) async {
      final app = await openPin(tester);
      await tester.tap(find.text('LUPA PIN? MASUK ULANG DENGAN EMAIL'));
      await tester.pumpAndSettle();
      expect(_location(app), AppRoutes.masuk);
    });
  });

  group('G1 Sesi berakhir', () {
    testWidgets('tampil di /kunci, Masuk lagi membuka 00e', (tester) async {
      final app = await pumpAuthApp(
        tester,
        session: const SessionState.expired(realUserId),
        profileName: 'Bayu',
        store: {
          StoreKeys.lastSyncedAt: DateTime(
            2026,
            11,
            20,
            8,
            12,
          ).toUtc().toIso8601String(),
        },
      );
      expect(_location(app), AppRoutes.kunci);
      expect(app.lock.biometricCalls, 0);
      expect(find.text('BELUM TERSINKRON SEJAK 08.12'), findsOneWidget);
      await _golden(tester, 'auth_g1_sesi_berakhir');

      await tester.tap(find.text('MASUK LAGI'));
      await tester.pumpAndSettle();
      expect(_location(app), AppRoutes.masuk);
    });

    testWidgets('sesi hilang saat app terbuka → G1', (tester) async {
      final app = await pumpAuthApp(
        tester,
        session: _locked,
        lock: FakeDeviceLock(biometric: [UnlockResult.success]),
      );
      expect(_location(app), AppRoutes.beranda);

      app.auth.expired.add(null);
      await tester.pumpAndSettle();
      expect(app.session, const SessionState.expired(realUserId));
      expect(_location(app), AppRoutes.kunci);
      expect(find.text('Sesi akun berakhir'), findsOneWidget);
    });
  });
}
