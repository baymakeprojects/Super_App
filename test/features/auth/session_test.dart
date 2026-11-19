import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:super_app/app/router.dart';
import 'package:super_app/app/routes.dart';
import 'package:super_app/core/db/database_provider.dart';
import 'package:super_app/core/storage/key_value_store.dart';
import 'package:super_app/features/auth/application/current_user_id_provider.dart';
import 'package:super_app/features/auth/application/session_controller.dart';
import 'package:super_app/features/auth/data/pin_store.dart';
import 'package:super_app/features/tugas/data/task_repository.dart';

import '../../helpers/test_database.dart';
import 'auth_fakes.dart';

void main() {
  group('keadaan saat app dibuka', () {
    test('sesi tersimpan = terkunci', () async {
      final auth = FakeAuth()..currentUserId = realUserId;
      expect(
        await readInitialSession(auth: auth, store: MemoryKeyValueStore()),
        const SessionState.locked(realUserId),
      );
    });

    test('tanpa sesi tapi pernah login = sesi berakhir (G1)', () async {
      final store = MemoryKeyValueStore({StoreKeys.lastUserId: realUserId});
      expect(
        await readInitialSession(auth: FakeAuth(), store: store),
        const SessionState.expired(realUserId),
      );
    });

    test('belum pernah login', () async {
      expect(
        await readInitialSession(
          auth: FakeAuth(),
          store: MemoryKeyValueStore(),
        ),
        const SessionState.signedOut(),
      );
    });

    test('tanpa file env (debug) = akun sementara dev-lokal', () async {
      expect(
        await readInitialSession(auth: null, store: MemoryKeyValueStore()),
        const SessionState.unlocked(devLocalUserId),
      );
    });
  });

  test('pengalihan rute mengikuti sesi', () {
    const out = SessionState.signedOut();
    const expired = SessionState.expired(realUserId);
    const locked = SessionState.locked(realUserId);
    const open = SessionState.unlocked(realUserId);

    expect(sessionRedirect(out, AppRoutes.beranda), AppRoutes.intro);
    expect(sessionRedirect(out, AppRoutes.masukKode), isNull);
    expect(sessionRedirect(expired, AppRoutes.tugas), AppRoutes.kunci);
    expect(sessionRedirect(expired, AppRoutes.kunciPin), AppRoutes.kunci);
    expect(sessionRedirect(expired, AppRoutes.masuk), isNull);
    expect(sessionRedirect(locked, AppRoutes.beranda), AppRoutes.kunci);
    expect(sessionRedirect(locked, AppRoutes.kunciPin), isNull);
    expect(sessionRedirect(open, AppRoutes.kunci), AppRoutes.beranda);
    expect(sessionRedirect(open, AppRoutes.masuk), AppRoutes.beranda);
    expect(sessionRedirect(open, AppRoutes.tugasBaru), isNull);
    const firstLogin = SessionState.unlocked(realUserId, needsSetup: true);
    expect(
      sessionRedirect(firstLogin, AppRoutes.masukKode),
      AppRoutes.setupJadwal,
    );
    expect(sessionRedirect(firstLogin, AppRoutes.setupDompet), isNull);
    expect(sessionRedirect(open, AppRoutes.setupKeamanan), AppRoutes.beranda);
  });

  test('login pertama memindahkan data dev-lokal ke akun asli', () async {
    final db = testDatabase();
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        initialSessionProvider.overrideWithValue(
          const SessionState.signedOut(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final devTasks = TaskRepository(db, userId: devLocalUserId);
    final id = await devTasks.addTask(title: 'Kuis');

    await container
        .read(sessionControllerProvider.notifier)
        .signedIn(realUserId);

    // Login pertama akun ini di HP → Setup awal (W4-01).
    expect(
      container.read(sessionControllerProvider),
      const SessionState.unlocked(realUserId, needsSetup: true),
    );
    final task = await (db.select(
      db.tasks,
    )..where((t) => t.id.equals(id))).getSingle();
    expect(task.userId, realUserId);
    // Antrean tetap, jadi tugas itu ikut terkirim saat sinkron pertama.
    expect(await db.select(db.syncQueue).get(), isNotEmpty);
    expect(container.read(sessionSyncUserIdProvider), realUserId);
  });

  test('sinkron mati selama sesi berakhir atau akun dev-lokal', () {
    for (final (session, expected) in [
      (const SessionState.expired(realUserId), null),
      (const SessionState.unlocked(devLocalUserId), null),
      (const SessionState.locked(realUserId), realUserId),
    ]) {
      final container = ProviderContainer(
        overrides: [initialSessionProvider.overrideWithValue(session)],
      );
      expect(
        container.read(sessionSyncUserIdProvider),
        expected,
        reason: '$session',
      );
      container.dispose();
    }
  });

  test('PIN cadangan harus 6 angka dan dicocokkan persis', () async {
    final pins = PinStore(MemoryKeyValueStore());
    expect(await pins.hasPin(), isFalse);
    expect(() => pins.setPin('12a456'), throwsArgumentError);
    await pins.setPin('123456');
    expect(await pins.verify('123456'), isTrue);
    expect(await pins.verify('12345'), isFalse);
    expect(await pins.verify('654321'), isFalse);
  });
}
