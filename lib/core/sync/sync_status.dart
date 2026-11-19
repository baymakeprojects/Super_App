import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:super_app/core/db/database_provider.dart';
import 'package:super_app/core/sync/sync_controller.dart';

/// Jumlah perubahan lokal yang belum terkirim: baris berbeda di antrean
/// (satu baris yang diubah dua kali tetap dihitung satu).
final pendingChangesProvider = StreamProvider<int>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return database
      .customSelect(
        'SELECT COUNT(*) AS n FROM '
        '(SELECT DISTINCT table_name, row_id FROM sync_queue)',
        readsFrom: {database.syncQueue},
      )
      .watchSingle()
      .map((row) => row.read<int>('n'));
});

/// Banner sinkron yang tampil di Beranda.
enum SyncBannerKind {
  /// E5: tidak ada internet, perubahan aman di HP.
  offline,

  /// G8: internet ada, tapi server menolak atau bermasalah.
  failed,
}

/// G8 tampil setelah sekian kegagalan server berturut-turut ("kalau gagal
/// lebih lama", PRD). Kegagalan pertama dicoba ulang diam-diam 30 detik
/// kemudian.
const int syncFailedBannerAfter = 2;

/// Galat karena tidak ada internet (bukan karena server).
bool isNetworkError(Object error) {
  if (error is SocketException ||
      error is TimeoutException ||
      error is HttpException) {
    return true;
  }
  // Supabase membungkus galat jaringan (ClientException dari paket http);
  // pesannya tetap memuat penyebab aslinya.
  final message = error.toString();
  return message.contains('SocketException') ||
      message.contains('Failed host lookup') ||
      message.contains('Connection refused') ||
      message.contains('Network is unreachable') ||
      message.contains('Connection closed');
}

/// Banner yang perlu tampil untuk [state], atau `null`.
///
/// Banner tetap tampil selama putaran coba ulang berjalan, supaya tidak
/// berkedip, dan hilang begitu satu putaran berhasil.
SyncBannerKind? syncBannerOf(SyncState state) {
  final error = state.lastError;
  if (error == null || state.failures == 0) return null;
  if (state.phase != SyncPhase.failed && state.phase != SyncPhase.syncing) {
    return null;
  }
  if (isNetworkError(error)) return SyncBannerKind.offline;
  return state.failures >= syncFailedBannerAfter ? SyncBannerKind.failed : null;
}

/// Isi banner E5. `null` (tanpa keterangan) kalau tidak ada perubahan yang
/// menunggu.
String? offlineBannerBody(int pending) => pending == 0
    ? null
    : '$pending perubahan tersimpan di HP, disinkron saat online';

/// Isi banner G8.
String failedBannerBody(int pending) => pending == 0
    ? 'Server sedang bermasalah.'
    : '$pending perubahan belum terkirim. Server sedang bermasalah.';

/// Banner yang tampil sekarang (dipakai layar).
final syncBannerProvider = Provider<SyncBannerKind?>(
  (ref) => syncBannerOf(ref.watch(syncControllerProvider)),
);
