import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:super_app/core/db/database_provider.dart';
import 'package:super_app/core/sync/remote_store.dart';
import 'package:super_app/core/sync/sync_engine.dart';
import 'package:super_app/core/utils/clock.dart';

/// Tempat data di server. `null` = sinkron mati (belum login; diisi setelah
/// login email + kode di W1-10, dengan id akun Supabase di
/// [syncUserIdProvider]).
final remoteStoreProvider = Provider<RemoteStore?>((ref) => null);

/// Id akun Supabase (uuid) untuk sinkron. `null` = belum login.
final syncUserIdProvider = Provider<String?>((ref) => null);

/// Keadaan sinkron, untuk banner offline E5 dan sinkron gagal G8 (W3-08).
enum SyncPhase {
  /// Belum login: data hanya di HP.
  disabled,

  /// Siap, belum ada putaran yang selesai.
  idle,

  /// Sedang mengirim atau menarik.
  syncing,

  /// Putaran terakhir berhasil.
  synced,

  /// Putaran terakhir gagal (offline atau server menolak); dicoba lagi.
  failed,
}

class SyncState {
  const SyncState({
    required this.phase,
    this.lastSyncedAt,
    this.lastError,
    this.failures = 0,
  });

  final SyncPhase phase;
  final DateTime? lastSyncedAt;
  final Object? lastError;

  /// Kegagalan berturut-turut (dasar jeda coba ulang).
  final int failures;
}

/// Jeda coba ulang setelah [failures] kegagalan berturut-turut: 30 detik,
/// lalu dua kali lipat, paling lama 15 menit.
Duration retryDelay(int failures) {
  const base = Duration(seconds: 30);
  const max = Duration(minutes: 15);
  final factor = math.pow(2, math.max(0, failures - 1)).toInt();
  final delay = base * factor;
  return delay > max ? max : delay;
}

/// Sinkron rutin saat semua sudah terkirim.
const Duration syncInterval = Duration(minutes: 5);

/// Jeda singkat setelah ada perubahan lokal, supaya beberapa perubahan
/// beruntun terkirim dalam satu putaran.
const Duration syncDebounce = Duration(seconds: 2);

final syncControllerProvider = NotifierProvider<SyncController, SyncState>(
  SyncController.new,
);

/// Menjalankan [SyncEngine]: saat app dibuka, setelah ada perubahan di
/// antrean, rutin tiap [syncInterval], dan coba ulang dengan [retryDelay]
/// setelah gagal.
class SyncController extends Notifier<SyncState> {
  Timer? _timer;
  StreamSubscription<int>? _queueWatch;
  bool _running = false;

  @override
  SyncState build() {
    final remote = ref.watch(remoteStoreProvider);
    final userId = ref.watch(syncUserIdProvider);
    ref.onDispose(() {
      _timer?.cancel();
      unawaited(_queueWatch?.cancel());
    });
    if (remote == null || userId == null) {
      return const SyncState(phase: SyncPhase.disabled);
    }

    // Perubahan baru di antrean → sinkron sebentar lagi.
    final database = ref.watch(appDatabaseProvider);
    final count = database.syncQueue.id.count();
    _queueWatch = (database.selectOnly(database.syncQueue)..addColumns([count]))
        .watchSingle()
        .map((row) => row.read(count) ?? 0)
        .listen((pending) {
          if (pending > 0) _schedule(syncDebounce);
        });
    _schedule(Duration.zero);
    return const SyncState(phase: SyncPhase.idle);
  }

  void _schedule(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, () => unawaited(syncNow()));
  }

  /// Satu putaran sekarang (juga untuk tombol "Coba lagi" di G8).
  Future<SyncResult?> syncNow() async {
    final remote = ref.read(remoteStoreProvider);
    final userId = ref.read(syncUserIdProvider);
    if (remote == null || userId == null || _running) return null;

    _running = true;
    _timer?.cancel();
    state = SyncState(
      phase: SyncPhase.syncing,
      lastSyncedAt: state.lastSyncedAt,
      failures: state.failures,
    );
    final result = await SyncEngine(
      ref.read(appDatabaseProvider),
      remote,
      userId: userId,
    ).sync();
    _running = false;
    if (!ref.mounted) return result;

    if (result.ok) {
      state = SyncState(
        phase: SyncPhase.synced,
        lastSyncedAt: ref.read(clockProvider)(),
      );
      _schedule(syncInterval);
    } else {
      final failures = state.failures + 1;
      state = SyncState(
        phase: SyncPhase.failed,
        lastSyncedAt: state.lastSyncedAt,
        lastError: result.error,
        failures: failures,
      );
      _schedule(retryDelay(failures));
    }
    return result;
  }
}
