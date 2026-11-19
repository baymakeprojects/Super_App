import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:super_app/app/app.dart';
import 'package:super_app/core/config/app_config.dart';
import 'package:super_app/core/storage/key_value_store.dart';
import 'package:super_app/core/sync/remote_store.dart';
import 'package:super_app/core/sync/sync_controller.dart';
import 'package:super_app/features/auth/application/session_controller.dart';
import 'package:super_app/features/auth/data/auth_repository.dart';
import 'package:super_app/features/auth/data/secure_session_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const store = SecureKeyValueStore();
  AuthRepository? auth;
  SupabaseClient? client;
  // Tanpa file env (`--dart-define-from-file`), login dan sinkron mati.
  if (AppConfig.hasSupabase) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseKey,
      authOptions: const FlutterAuthClientOptions(
        localStorage: SecureSessionStorage(store),
      ),
    );
    client = Supabase.instance.client;
    auth = SupabaseAuthRepository(client.auth);
  }
  final initialSession = await readInitialSession(auth: auth, store: store);

  runApp(
    ProviderScope(
      overrides: [
        keyValueStoreProvider.overrideWithValue(store),
        authRepositoryProvider.overrideWithValue(auth),
        initialSessionProvider.overrideWithValue(initialSession),
        if (client != null)
          remoteStoreProvider.overrideWithValue(SupabaseRemoteStore(client)),
        syncUserIdProvider.overrideWith(
          (ref) => ref.watch(sessionSyncUserIdProvider),
        ),
      ],
      child: const SuperApp(),
    ),
  );
}
