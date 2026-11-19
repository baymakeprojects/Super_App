import 'package:supabase_flutter/supabase_flutter.dart';

/// Tempat data di server. Mesin sinkron hanya bicara lewat antarmuka ini,
/// jadi bisa dites dengan versi palsu (misalnya pura-pura offline) tanpa
/// internet dan tanpa kunci Supabase.
abstract interface class RemoteStore {
  /// Simpan satu baris (insert atau update menurut `id`). Kolom snake_case,
  /// tanggal string ISO UTC.
  Future<void> upsert(String table, Map<String, Object?> row);

  /// Baris milik [userId] yang `updated_at`-nya setelah [since] (semua kalau
  /// `null`), urut `updated_at` naik.
  Future<List<Map<String, dynamic>>> fetchChanged(
    String table, {
    required String userId,
    DateTime? since,
  });
}

/// [RemoteStore] lewat Supabase. RLS di server tetap memastikan akun hanya
/// bisa membaca dan menulis barisnya sendiri; filter `user_id` di sini hanya
/// memperkecil data yang ditarik.
class SupabaseRemoteStore implements RemoteStore {
  SupabaseRemoteStore(this._client);

  final SupabaseClient _client;

  @override
  Future<void> upsert(String table, Map<String, Object?> row) =>
      _client.from(table).upsert(row);

  @override
  Future<List<Map<String, dynamic>>> fetchChanged(
    String table, {
    required String userId,
    DateTime? since,
  }) async {
    var query = _client.from(table).select().eq('user_id', userId);
    if (since != null) {
      query = query.gt('updated_at', since.toUtc().toIso8601String());
    }
    return query.order('updated_at', ascending: true);
  }
}
