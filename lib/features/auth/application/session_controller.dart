import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:super_app/core/db/database_provider.dart';
import 'package:super_app/core/storage/key_value_store.dart';
import 'package:super_app/features/auth/application/current_user_id_provider.dart';
import 'package:super_app/features/auth/data/auth_repository.dart';
import 'package:super_app/features/auth/data/dev_account_adoption.dart';
import 'package:super_app/features/auth/data/device_lock.dart';
import 'package:super_app/features/auth/data/pin_store.dart';

/// Login lewat Supabase. `null` = app dijalankan tanpa file env (login dan
/// sinkron mati). Diisi di `main.dart`.
final authRepositoryProvider = Provider<AuthRepository?>((ref) => null);

final deviceLockProvider = Provider<DeviceLock>((ref) => LocalAuthDeviceLock());

final pinStoreProvider = Provider<PinStore>(
  (ref) => PinStore(ref.watch(keyValueStoreProvider)),
);

/// Keadaan login saat app dibuka (dibaca di `main.dart` sebelum app tampil).
final initialSessionProvider = Provider<SessionState>(
  (ref) => kDebugMode
      ? const SessionState.unlocked(devLocalUserId)
      : const SessionState.signedOut(),
);

/// Tahap login app (navigasi.md › Alur saat app dibuka).
enum SessionStatus {
  /// Belum pernah login: Intro → Masuk dengan email.
  signedOut,

  /// Pernah login tapi sesi hilang (G1). Data di HP tetap ada.
  expired,

  /// Sudah login, app baru dibuka: Kunci sidik jari (01).
  locked,

  /// Sudah login dan kunci terbuka.
  unlocked,
}

@immutable
class SessionState {
  const SessionState.signedOut()
    : status = SessionStatus.signedOut,
      userId = null;
  const SessionState.expired(String this.userId)
    : status = SessionStatus.expired;
  const SessionState.locked(String this.userId) : status = SessionStatus.locked;
  const SessionState.unlocked(String this.userId)
    : status = SessionStatus.unlocked;

  final SessionStatus status;

  /// Akun pemilik data di HP; `null` hanya saat belum pernah login.
  final String? userId;

  /// Login dengan akun Supabase asli (bukan akun sementara `dev-lokal`).
  bool get hasRealAccount => userId != null && userId != devLocalUserId;

  @override
  bool operator ==(Object other) =>
      other is SessionState && other.status == status && other.userId == userId;

  @override
  int get hashCode => Object.hash(status, userId);

  @override
  String toString() => 'SessionState($status, $userId)';
}

/// Menentukan keadaan login saat app dibuka.
Future<SessionState> readInitialSession({
  required AuthRepository? auth,
  required KeyValueStore store,
}) async {
  if (auth == null) {
    return kDebugMode
        ? const SessionState.unlocked(devLocalUserId)
        : const SessionState.signedOut();
  }
  final userId = auth.currentUserId;
  if (userId != null) return SessionState.locked(userId);
  final lastUserId = await store.read(StoreKeys.lastUserId);
  return lastUserId == null
      ? const SessionState.signedOut()
      : SessionState.expired(lastUserId);
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    final auth = ref.watch(authRepositoryProvider);
    if (auth != null) {
      final sub = auth.sessionExpired.listen((_) => _expire());
      ref.onDispose(sub.cancel);
    }
    return ref.watch(initialSessionProvider);
  }

  void _expire() {
    final userId = state.userId;
    if (userId == null || !state.hasRealAccount) return;
    state = SessionState.expired(userId);
  }

  /// Kode verifikasi cocok. Data akun sementara `dev-lokal` dipindahkan ke
  /// akun ini, lalu app terbuka tanpa kunci (baru saja membuktikan diri).
  Future<void> signedIn(String userId) async {
    await adoptDevLocalRows(ref.read(appDatabaseProvider), userId);
    await ref.read(keyValueStoreProvider).write(StoreKeys.lastUserId, userId);
    state = SessionState.unlocked(userId);
  }

  /// Sidik jari atau PIN cocok.
  void unlock() {
    final userId = state.userId;
    if (state.status != SessionStatus.locked || userId == null) return;
    state = SessionState.unlocked(userId);
  }
}

/// Id akun untuk sinkron: hanya akun Supabase asli yang sesinya masih
/// berlaku (terkunci atau terbuka). `null` = sinkron mati.
final sessionSyncUserIdProvider = Provider<String?>((ref) {
  final session = ref.watch(sessionControllerProvider);
  final active =
      session.status == SessionStatus.locked ||
      session.status == SessionStatus.unlocked;
  return active && session.hasRealAccount ? session.userId : null;
});
