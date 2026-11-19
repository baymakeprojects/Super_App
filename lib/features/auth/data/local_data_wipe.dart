import 'package:super_app/core/db/app_database.dart';

/// Menghapus salinan data di HP setelah keluar akun (P38: "Data di HP ini
/// akan dihapus ... tetap aman di cloud"). Data di Supabase tidak disentuh.
///
/// Hanya dihapus kalau antrean sinkron kosong, supaya perubahan yang belum
/// terkirim tidak hilang (F-55). Mengembalikan `true` kalau dihapus.
Future<bool> wipeLocalDataIfSynced(AppDatabase database) {
  return database.transaction(() async {
    final pending = await database.select(database.syncQueue).get();
    if (pending.isNotEmpty) return false;
    for (final table in database.allTables) {
      await database.delete(table).go();
    }
    return true;
  });
}
