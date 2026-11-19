import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:super_app/core/storage/key_value_store.dart';

/// Tempat Supabase menyimpan sesi login: di [KeyValueStore] terenkripsi,
/// bukan SharedPreferences biasa (spesifikasi-teknis: sesi di
/// flutter_secure_storage).
class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage(this._store);

  final KeyValueStore _store;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async =>
      await _store.read(StoreKeys.session) != null;

  @override
  Future<String?> accessToken() => _store.read(StoreKeys.session);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _store.write(StoreKeys.session, persistSessionString);

  @override
  Future<void> removePersistedSession() => _store.delete(StoreKeys.session);
}
