import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/app.dart';
import 'package:super_app/app/router.dart';
import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/db/database_provider.dart';
import 'package:super_app/core/storage/key_value_store.dart';
import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/features/auth/application/session_controller.dart';
import 'package:super_app/features/auth/data/auth_repository.dart';
import 'package:super_app/features/auth/data/device_lock.dart';

import '../../helpers/svg.dart';
import '../../helpers/test_database.dart';

const String realUserId = '22222222-2222-4222-8222-222222222222';
const String validCode = '482193';

/// [AuthRepository] palsu: kode benar [validCode], tanpa internet.
class FakeAuth implements AuthRepository {
  @override
  String? currentUserId;

  final StreamController<void> expired = StreamController<void>.broadcast();

  /// Diisi = kirim kode melempar ini (misalnya offline).
  Object? sendError;

  /// Diisi = kirim atau periksa kode menunggu sampai selesai.
  Completer<void>? hold;

  /// Diisi = periksa kode ditolak dengan alasan ini.
  CodeRejection? verifyRejection;

  final List<String> sentTo = [];

  @override
  Stream<void> get sessionExpired => expired.stream;

  @override
  Future<void> sendCode(String email) async {
    await hold?.future;
    if (sendError case final error?) throw error;
    sentTo.add(email);
  }

  @override
  Future<String> verifyCode({
    required String email,
    required String code,
  }) async {
    await hold?.future;
    if (verifyRejection case final reason?) {
      throw CodeRejectedException(reason);
    }
    if (code != validCode) {
      throw const CodeRejectedException(CodeRejection.rejected);
    }
    currentUserId = realUserId;
    return realUserId;
  }

  @override
  Future<void> signOut() async => currentUserId = null;
}

/// [DeviceLock] palsu: hasil sidik jari diambil berurutan dari
/// [biometric] (habis = dibatalkan).
class FakeDeviceLock implements DeviceLock {
  FakeDeviceLock({
    List<UnlockResult>? biometric,
    this.credential = UnlockResult.canceled,
  }) : biometric = biometric ?? [];

  final List<UnlockResult> biometric;
  UnlockResult credential;
  int biometricCalls = 0;
  int credentialCalls = 0;

  @override
  Future<UnlockResult> unlockWithBiometric() async {
    biometricCalls++;
    return biometric.isEmpty ? UnlockResult.canceled : biometric.removeAt(0);
  }

  @override
  Future<UnlockResult> unlockWithDeviceCredential() async {
    credentialCalls++;
    return credential;
  }
}

/// Jam yang bisa dimajukan di tes.
class TestClock {
  TestClock(this.now);

  DateTime now;

  DateTime call() => now;
}

/// App lengkap (router dengan pengalihan sesi) di ukuran HP Figma.
class AuthHarness {
  AuthHarness({
    required this.container,
    required this.database,
    required this.auth,
    required this.lock,
    required this.store,
    required this.clock,
  });

  final ProviderContainer container;
  final AppDatabase database;
  final FakeAuth auth;
  final FakeDeviceLock lock;
  final MemoryKeyValueStore store;
  final TestClock clock;

  GoRouter get router => container.read(appRouterProvider);
  SessionState get session => container.read(sessionControllerProvider);
}

Future<AuthHarness> pumpAuthApp(
  WidgetTester tester, {
  required SessionState session,
  FakeAuth? auth,
  FakeDeviceLock? lock,
  Map<String, String>? store,
  String? profileName,
  bool settle = true,
}) async {
  tester.view
    ..physicalSize = const Size(412, 917)
    ..devicePixelRatio = 1
    ..padding = const FakeViewPadding(top: 32)
    ..viewPadding = const FakeViewPadding(top: 32);
  addTearDown(tester.view.reset);

  final database = testDatabase();
  addTearDown(database.close);
  if (profileName != null && session.userId != null) {
    await database
        .into(database.profiles)
        .insert(
          ProfilesCompanion.insert(
            id: 'p1',
            userId: session.userId!,
            name: Value(profileName),
          ),
        );
  }

  final fakeAuth = auth ?? FakeAuth();
  final fakeLock = lock ?? FakeDeviceLock();
  final memory = MemoryKeyValueStore(store);
  final clock = TestClock(DateTime(2026, 11, 20, 7, 2));
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      initialSessionProvider.overrideWithValue(session),
      authRepositoryProvider.overrideWithValue(fakeAuth),
      deviceLockProvider.overrideWithValue(fakeLock),
      keyValueStoreProvider.overrideWithValue(memory),
      clockProvider.overrideWithValue(clock.call),
    ],
  );
  addTearDown(container.dispose);

  await precacheAppIcons(tester);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const SuperApp()),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return AuthHarness(
    container: container,
    database: database,
    auth: fakeAuth,
    lock: fakeLock,
    store: memory,
    clock: clock,
  );
}
