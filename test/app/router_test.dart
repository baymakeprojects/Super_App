import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:super_app/app/app.dart';
import 'package:super_app/app/router.dart';
import 'package:super_app/app/routes.dart';
import 'package:super_app/core/db/database_provider.dart';

import '../helpers/test_database.dart';

Future<GoRouter> _pumpApp(WidgetTester tester) async {
  final router = buildAppRouter();
  addTearDown(router.dispose);
  // Tab Tugas membaca database: pakai database di memori, bukan file HP.
  final database = testDatabase();
  addTearDown(database.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appRouterProvider.overrideWithValue(router),
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const SuperApp(),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

String _location(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.toString();

Future<void> _go(WidgetTester tester, GoRouter router, String path) async {
  router.go(path);
  await tester.pumpAndSettle();
}

/// Tombol Back Android.
Future<void> _pressBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  // Semua rute di tabel docs/navigasi.md beserta judul layarnya.
  final routes = <String, String>{
    AppRoutes.intro: 'Intro',
    AppRoutes.kunci: 'Kunci sidik jari',
    AppRoutes.kunciPin: 'Masukkan PIN',
    AppRoutes.setupJadwal: 'Jadwal semester',
    AppRoutes.setupDompet: 'Dompet & saldo awal',
    AppRoutes.setupKeamanan: 'Keamanan',
    AppRoutes.beranda: 'Halo',
    AppRoutes.tugas: 'Tugas',
    AppRoutes.tugasBaru: 'Tugas baru',
    AppRoutes.tugasCari: 'Pencarian',
    AppRoutes.tugasDetail('t1'): 'Detail tugas',
    AppRoutes.tugasEdit('t1'): 'Edit tugas',
    AppRoutes.kuliah: 'Kuliah',
    AppRoutes.kuliahJadwalBaru: 'Jadwal baru',
    AppRoutes.kuliahDetail('c1'): 'Mata kuliah',
    AppRoutes.kuliahEdit('c1'): 'Ubah jadwal',
    AppRoutes.keuangan: 'Keuangan',
    AppRoutes.keuanganTransaksiBaru: 'Transaksi baru',
    AppRoutes.keuanganTransaksi('x1'): 'Ubah transaksi',
    AppRoutes.lainnya: 'Lainnya',
    AppRoutes.pengaturan: 'Pengaturan',
    AppRoutes.pengaturanPin: 'Atur PIN cadangan',
  };

  testWidgets('app mulai di Beranda dengan Bottom Nav', (tester) async {
    final router = await _pumpApp(tester);

    expect(_location(router), AppRoutes.beranda);
    expect(find.text('Halo'), findsOneWidget);
    expect(find.text('KEUANGAN'), findsOneWidget);
  });

  testWidgets('semua rute di navigasi.md bisa dibuka', (tester) async {
    final router = await _pumpApp(tester);

    for (final MapEntry(key: path, value: title) in routes.entries) {
      await _go(tester, router, path);
      expect(_location(router), path, reason: path);
      expect(find.text(title), findsWidgets, reason: '$path → "$title"');
    }
  });

  testWidgets('rute debug /katalog membuka katalog komponen', (tester) async {
    final router = await _pumpApp(tester);
    await _go(tester, router, AppRoutes.katalog);
    expect(find.text('Katalog komponen'), findsOneWidget);
  });

  testWidgets('Bottom Nav berpindah tab', (tester) async {
    final router = await _pumpApp(tester);

    await tester.tap(find.text('KEUANGAN'));
    await tester.pumpAndSettle();
    expect(_location(router), AppRoutes.keuangan);

    await tester.tap(find.text('TUGAS'));
    await tester.pumpAndSettle();
    expect(_location(router), AppRoutes.tugas);
  });

  group('aturan Back', () {
    testWidgets('di tab selain Beranda, Back pindah ke Beranda', (
      tester,
    ) async {
      final router = await _pumpApp(tester);
      await _go(tester, router, AppRoutes.kuliah);

      await _pressBack(tester);
      expect(_location(router), AppRoutes.beranda);
    });

    testWidgets('di Beranda, Back keluar dari app', (tester) async {
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      final router = await _pumpApp(tester);
      await _pressBack(tester);

      expect(calls, contains('SystemNavigator.pop'));
      expect(_location(router), AppRoutes.beranda);
    });

    testWidgets('dari detail, Back kembali ke tab asal dengan Bottom Nav', (
      tester,
    ) async {
      final router = await _pumpApp(tester);
      await _go(tester, router, AppRoutes.tugasEdit('t1'));
      expect(find.text('KEUANGAN'), findsNothing);

      await _pressBack(tester);
      expect(_location(router), AppRoutes.tugasDetail('t1'));

      await _pressBack(tester);
      expect(_location(router), AppRoutes.tugas);
      expect(find.text('KEUANGAN'), findsOneWidget);
    });

    testWidgets('panah kiri di Top App Bar sama dengan Back', (tester) async {
      final router = await _pumpApp(tester);
      // Layar sementara (H04 Pencarian belum dibuat) punya panah kiri.
      await _go(tester, router, AppRoutes.tugasCari);

      await tester.tap(find.bySemanticsLabel('Kembali'));
      await tester.pumpAndSettle();
      expect(_location(router), AppRoutes.tugas);
    });
  });
}
