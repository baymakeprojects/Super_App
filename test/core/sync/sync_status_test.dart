import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:super_app/core/db/database_provider.dart';
import 'package:super_app/core/sync/sync_controller.dart';
import 'package:super_app/core/sync/sync_status.dart';
import 'package:super_app/features/tugas/data/task_repository.dart';

import '../../helpers/test_database.dart';

const String _user = '11111111-1111-4111-8111-111111111111';

SyncState _failed(Object error, {int failures = 1, SyncPhase? phase}) =>
    SyncState(
      phase: phase ?? SyncPhase.failed,
      lastError: error,
      failures: failures,
    );

void main() {
  group('jenis galat', () {
    test('tanpa internet = offline', () {
      expect(isNetworkError(const SocketException('no route')), isTrue);
      expect(isNetworkError(TimeoutException('lama')), isTrue);
      // Bentuk pesan ClientException dari paket http lewat Supabase.
      expect(
        isNetworkError(
          Exception('ClientException with SocketException: Failed host lookup'),
        ),
        isTrue,
      );
    });

    test('server menolak = bukan offline', () {
      expect(isNetworkError(Exception('500 Internal Server Error')), isFalse);
      expect(isNetworkError(StateError('RLS')), isFalse);
    });
  });

  group('banner', () {
    test('E5 langsung saat offline, juga selama coba ulang', () {
      const offline = SocketException('offline');
      expect(syncBannerOf(_failed(offline)), SyncBannerKind.offline);
      expect(
        syncBannerOf(_failed(offline, phase: SyncPhase.syncing)),
        SyncBannerKind.offline,
      );
    });

    test('G8 baru setelah gagal lebih lama (2 kali berturut-turut)', () {
      final server = Exception('500');
      expect(syncBannerOf(_failed(server)), isNull);
      expect(
        syncBannerOf(_failed(server, failures: syncFailedBannerAfter)),
        SyncBannerKind.failed,
      );
    });

    test('tidak tampil saat sinkron mati, siap, atau berhasil', () {
      expect(syncBannerOf(const SyncState(phase: SyncPhase.disabled)), isNull);
      expect(syncBannerOf(const SyncState(phase: SyncPhase.idle)), isNull);
      expect(syncBannerOf(const SyncState(phase: SyncPhase.synced)), isNull);
    });

    test('teks keterangan mengikuti jumlah perubahan', () {
      expect(
        offlineBannerBody(3),
        '3 perubahan tersimpan di HP, disinkron saat online',
      );
      expect(offlineBannerBody(0), isNull);
      expect(
        failedBannerBody(3),
        '3 perubahan belum terkirim. Server sedang bermasalah.',
      );
      expect(failedBannerBody(0), 'Server sedang bermasalah.');
    });
  });

  test('jumlah perubahan = baris berbeda di antrean', () async {
    final db = testDatabase();
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(pendingChangesProvider, (_, _) {});
    addTearDown(sub.close);

    final tasks = TaskRepository(db, userId: _user);
    final id = await tasks.addTask(title: 'Kuis');
    await tasks.updateTask(id, title: 'Kuis bab 4'); // baris yang sama
    await tasks.addTask(title: 'Laporan');

    await pumpEventQueue();
    expect(container.read(pendingChangesProvider).value, 2);
  });
}
