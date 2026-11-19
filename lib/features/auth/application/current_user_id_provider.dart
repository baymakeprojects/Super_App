import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:super_app/features/auth/application/session_controller.dart';

/// Id akun sementara untuk mencoba app di build debug tanpa file env
/// (keputusan Bayu, W2-02). Tidak pernah dipakai di build rilis.
///
/// Saat login pertama, baris dengan id ini dipindahkan ke akun asli
/// sebelum sinkron pertama (`adoptDevLocalRows`).
const String devLocalUserId = 'dev-lokal';

/// Id akun pemilik data di HP, untuk kolom `user_id`.
///
/// Melempar error kalau belum pernah login: layar data hanya bisa dibuka
/// setelah login, jadi tidak ada data tanpa pemilik.
final currentUserIdProvider = Provider<String>((ref) {
  final userId = ref.watch(sessionControllerProvider.select((s) => s.userId));
  if (userId == null) {
    throw StateError('Belum ada akun yang login.');
  }
  return userId;
});
