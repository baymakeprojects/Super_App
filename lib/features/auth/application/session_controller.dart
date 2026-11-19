import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:super_app/core/db/database_provider.dart';
import 'package:super_app/core/storage/key_value_store.dart';
import 'package:super_app/core/sync/sync_controller.dart';
import 'package:super_app/features/auth/application/current_user_id_provider.dart';
import 'package:super_app/features/auth/data/auth_repository.dart';
import 'package:super_app/features/auth/data/dev_account_adoption.dart';
import 'package:super_app/features/auth/data/device_lock.dart';
import 'package:super_app/features/auth/data/local_data_wipe.dart';
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
      userId = null,
      needsSetup = false;
  const SessionState.expired(String this.userId)
    : status = SessionStatus.expired,
      needsSetup = false;
  const SessionState.locked(String this.userId)
    : status = SessionStatus.locked,
      needsSetup = false;
  const SessionState.unlocked(String this.userId, {this.needsSetup = false})
    : status = SessionStatus.unlocked;

  final SessionStatus status;

  /// Login pertama akun ini di HP: Setup awal 01a–01c belum dilewati atau
  /// diselesaikan (navigasi.md › Alur saat app dibuka).
  final bool needsSetup;

  /// Akun pemilik data di HP; `null` hanya saat belum pernah login.
  final String? userId;

  /// Login dengan akun Supabase asli (bukan akun sementara `dev-lokal`).
  bool get hasRealAccount => userId != null && userId != devLocalUserId;

  @override
  bool operator ==(Object other) =>
      other is SessionState &&
      other.status == status &&
      other.userId == userId &&
      other.needsSetup == needsSetup;

  @override
  int get hashCode => Object.hash(status, userId, needsSetup);

  @override
  String toString() =>
      'SessionState($status, $userId${needsSetup ? ', setup' : ''})';
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
  if (userId != null) {
    // Kunci sidik jari dimatikan di 01c: app langsung terbuka.
    return await isBiometricLockOn(store)
        ? SessionState.locked(userId)
        : SessionState.unlocked(userId);
  }
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
    final store = ref.read(keyValueStoreProvider);
    await adoptDevLocalRows(ref.read(appDatabaseProvider), userId);
    await store.write(StoreKeys.lastUserId, userId);
    final setupDone = await store.read(StoreKeys.setupDone(userId)) != null;
    state = SessionState.unlocked(userId, needsSetup: !setupDone);
  }

  /// "Lewati" atau "Selesai, ke Beranda" di Setup awal.
  Future<void> finishSetup() async {
    final userId = state.userId;
    if (userId == null) return;
    await ref
        .read(keyValueStoreProvider)
        .write(StoreKeys.setupDone(userId), 'ya');
    state = SessionState.unlocked(userId);
  }

  /// P38 "Keluar": kirim perubahan terakhir, keluar dari Supabase, lalu
  /// hapus salinan data di HP kalau semuanya sudah terkirim (F-55). PIN,
  /// pilihan kunci sidik jari, dan id akun terakhir ikut dihapus, jadi app
  /// kembali ke Intro (bukan G1).
  Future<void> signOut() async {
    await ref.read(syncControllerProvider.notifier).syncNow();
    await ref.read(authRepositoryProvider)?.signOut();
    await wipeLocalDataIfSynced(ref.read(appDatabaseProvider));
    final store = ref.read(keyValueStoreProvider);
    for (final key in [
      StoreKeys.lastUserId,
      StoreKeys.pin,
      StoreKeys.biometricLock,
      StoreKeys.lastSyncedAt,
    ]) {
      await store.delete(key);
    }
    ref
      ..invalidate(hasPinProvider)
      ..invalidate(biometricLockProvider);
    state = const SessionState.signedOut();
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

/// Kunci sidik jari aktif (switch di 01c). Bawaan aktif.
Future<bool> isBiometricLockOn(KeyValueStore store) async =>
    await store.read(StoreKeys.biometricLock) != 'mati';

/// Nilai switch "Kunci sidik jari" (01c, nanti juga 14 Pengaturan).
final biometricLockProvider =
    AsyncNotifierProvider<BiometricLockController, bool>(
      BiometricLockController.new,
    );

class BiometricLockController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => isBiometricLockOn(ref.watch(keyValueStoreProvider));

  Future<void> set({required bool on}) async {
    state = AsyncData(on);
    final store = ref.read(keyValueStoreProvider);
    if (on) {
      await store.delete(StoreKeys.biometricLock);
    } else {
      await store.write(StoreKeys.biometricLock, 'mati');
    }
  }
}

/// PIN cadangan sudah diatur (baris "PIN cadangan" di 01c dan 14).
final hasPinProvider = FutureProvider<bool>(
  (ref) => ref.watch(pinStoreProvider).hasPin(),
);

/// Email akun yang login, `null` tanpa Supabase (akun `dev-lokal`).
final accountEmailProvider = Provider<String?>((ref) {
  ref.watch(sessionControllerProvider.select((s) => s.userId));
  return ref.watch(authRepositoryProvider)?.currentEmail;
});
