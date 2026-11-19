import 'package:drift/drift.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/sync/sync_engine.dart';
import 'package:super_app/features/auth/application/current_user_id_provider.dart';

/// Memindahkan data yang dicatat dengan akun sementara [devLocalUserId]
/// (build debug sebelum login) ke akun asli [userId], sebelum sinkron
/// pertama. Antrean sinkron tetap, jadi baris itu ikut terkirim.
///
/// Profil `dev-lokal` dihapus: profil akun asli dibuat server.
Future<void> adoptDevLocalRows(AppDatabase database, String userId) {
  return database.transaction(() async {
    final devProfiles = await (database.select(
      database.profiles,
    )..where((p) => p.userId.equals(devLocalUserId))).get();
    for (final profile in devProfiles) {
      await (database.delete(database.syncQueue)..where(
            (q) =>
                q.targetTable.equals('profiles') & q.rowId.equals(profile.id),
          ))
          .go();
    }
    await (database.delete(
      database.profiles,
    )..where((p) => p.userId.equals(devLocalUserId))).go();

    for (final table in SyncEngine.tables) {
      if (table == 'profiles') continue;
      await database.customUpdate(
        'UPDATE "$table" SET user_id = ? WHERE user_id = ?',
        variables: [
          Variable.withString(userId),
          Variable.withString(devLocalUserId),
        ],
        updates: {
          database.allTables.firstWhere((t) => t.actualTableName == table),
        },
      );
    }
  });
}
