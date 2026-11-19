import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Id akun sementara untuk mencoba app di build debug sebelum login ada
/// (keputusan Bayu, W2-02). Tidak pernah dipakai di build rilis.
///
/// Saat login dibuat (W1-10), baris dengan id ini dipindahkan ke id akun
/// asli sebelum sinkron pertama, atau dihapus.
const String devLocalUserId = 'dev-lokal';

/// Id akun yang sedang login, untuk kolom `user_id`.
///
/// Sampai login dibuat di W1-10: build debug memakai [devLocalUserId],
/// build rilis melempar error supaya tidak ada data tanpa pemilik asli.
final currentUserIdProvider = Provider<String>((ref) {
  if (kDebugMode) return devLocalUserId;
  throw StateError('Belum ada akun yang login (login dibuat di W1-10).');
});
