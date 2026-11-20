// Uji integrasi alur utama (pengujian-rilis.md › Integrasi), dijalankan
// dengan `flutter test` tanpa HP: app lengkap dengan login palsu dan
// server palsu yang bisa dibuat offline.
//
// Login → setup → tambah tugas → offline (E5) → online lagi → tersinkron.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/routes.dart';
import 'package:super_app/core/sync/remote_store.dart';
import 'package:super_app/core/sync/sync_controller.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/features/auth/application/session_controller.dart';
import 'package:super_app/features/beranda/presentation/beranda_screen.dart';

import '../features/auth/auth_fakes.dart';

/// Supabase palsu di memori. Offline = galat jaringan seperti di HP.
class _FakeServer implements RemoteStore {
  final Map<String, Map<String, Map<String, Object?>>> tables = {};
  bool offline = false;

  void _check() {
    if (offline) {
      throw const SocketException('Failed host lookup: supabase.co');
    }
  }

  @override
  Future<void> upsert(String table, Map<String, Object?> row) async {
    _check();
    tables.putIfAbsent(table, () => {})[row['id']! as String] = Map.of(row);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchChanged(
    String table, {
    required String userId,
    DateTime? since,
  }) async {
    _check();
    return const [];
  }
}

Finder _input(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.byType(AppInput)),
  matching: find.byType(TextField),
);

void main() {
  testWidgets('login, setup, tambah tugas, offline, lalu tersinkron', (
    tester,
  ) async {
    final server = _FakeServer();
    final app = await pumpAuthApp(
      tester,
      session: const SessionState.signedOut(),
      extraOverrides: [
        remoteStoreProvider.overrideWithValue(server),
        syncUserIdProvider.overrideWith(
          (ref) => ref.watch(sessionSyncUserIdProvider),
        ),
      ],
    );

    // 1. Intro 1–4 → Masuk dengan email → kode → Setup awal.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('LANJUT →'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('MULAI SEKARANG →'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'bayu@email.com');
    await tester.tap(find.text('KIRIM KODE →'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(find.byType(TextField), validCode);
    await tester.pump();
    await tester.tap(find.text('MASUK →'));
    await tester.pumpAndSettle();
    expect(app.router.state.matchedLocation, AppRoutes.setupJadwal);

    // 2. Lewati setup → Beranda E1. Sinkron pertama (online) berhasil.
    await tester.tap(find.text('LEWATI'));
    await tester.pumpAndSettle();
    expect(find.byType(BerandaScreen), findsOneWidget);
    expect(app.container.read(syncControllerProvider).phase, SyncPhase.synced);

    // 3. Internet mati, lalu tambah tugas lewat checklist E1.
    server.offline = true;
    await tester.tap(find.text('Tambah tugas pertama'));
    await tester.pumpAndSettle();
    await tester.enterText(_input('JUDUL TUGAS'), 'Laporan praktikum modul 5');
    await tester.tap(find.text('SIMPAN TUGAS'));
    await tester.pumpAndSettle();
    expect(find.byType(BerandaScreen), findsOneWidget);

    // Sinkron setelah jeda singkat gagal: tugas aman di HP, banner E5.
    await tester.pump(syncDebounce + const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Kamu sedang offline'), findsOneWidget);
    expect(server.tables['tasks'] ?? const {}, isEmpty);

    // 4. Online lagi → "Coba lagi" → tugas sampai di server, banner hilang.
    server.offline = false;
    await tester.tap(find.text('COBA LAGI'));
    await tester.pumpAndSettle();
    expect(find.text('Kamu sedang offline'), findsNothing);
    final tasks = server.tables['tasks']!.values.toList();
    expect(tasks, hasLength(1));
    expect(tasks.single['title'], 'Laporan praktikum modul 5');
    expect(tasks.single['user_id'], realUserId);
    expect(await app.database.select(app.database.syncQueue).get(), isEmpty);

    // Timer sinkron rutin dihentikan sebelum tes selesai.
    await tester.pumpWidget(const SizedBox.shrink());
    app.container.dispose();
  });
}
