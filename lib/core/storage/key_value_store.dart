import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Penyimpanan rahasia di HP. Diganti versi terenkripsi di `main.dart`.
final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => MemoryKeyValueStore(),
);

/// Tempat menyimpan nilai kecil yang rahasia (sesi Supabase, PIN, id akun
/// terakhir). Antarmuka supaya bisa diganti versi memori di tes.
abstract interface class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// [KeyValueStore] terenkripsi di HP (Android Keystore) lewat
/// flutter_secure_storage.
class SecureKeyValueStore implements KeyValueStore {
  const SecureKeyValueStore();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// [KeyValueStore] di memori: untuk tes dan untuk app tanpa file env.
class MemoryKeyValueStore implements KeyValueStore {
  MemoryKeyValueStore([Map<String, String>? values]) : _values = {...?values};

  final Map<String, String> _values;

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

/// Kunci yang dipakai app di [KeyValueStore].
abstract final class StoreKeys {
  /// Sesi Supabase (JSON).
  static const String session = 'supabase.session';

  /// Id akun terakhir yang login. Masih ada padahal sesi hilang = sesi
  /// berakhir (G1), bukan belum pernah login.
  static const String lastUserId = 'auth.last_user_id';

  /// PIN cadangan 6 angka (diatur di H05, W4-04).
  static const String pin = 'auth.pin';

  /// Waktu sinkron terakhir yang berhasil (ISO), untuk baris status G1.
  static const String lastSyncedAt = 'sync.last_synced_at';
}
