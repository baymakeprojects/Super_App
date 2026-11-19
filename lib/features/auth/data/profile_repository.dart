import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/db/database_provider.dart';
import 'package:super_app/features/auth/application/current_user_id_provider.dart';

/// Profil akun (nama untuk sapaan "Halo, Bayu"). Profil dibuat oleh trigger
/// database saat akun pertama kali dibuat dan ikut sinkron.
class ProfileRepository {
  ProfileRepository(this._database, {required this.userId});

  final AppDatabase _database;
  final String userId;

  /// Nama akun, `null` kalau belum ada profil atau nama masih kosong (login
  /// email tidak memberi nama, F-14).
  Stream<String?> watchName() {
    final query = _database.select(_database.profiles)
      ..where((p) => p.userId.equals(userId) & p.deletedAt.isNull())
      ..limit(1);
    return query.watchSingleOrNull().map((profile) {
      final name = profile?.name?.trim();
      return (name == null || name.isEmpty) ? null : name;
    });
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    ref.watch(appDatabaseProvider),
    userId: ref.watch(currentUserIdProvider),
  );
});

/// Nama untuk sapaan (01, H06, G1, Beranda) dan avatar. `null` = belum ada
/// nama (F-14, F-45).
final profileNameProvider = StreamProvider<String?>(
  (ref) => ref.watch(profileRepositoryProvider).watchName(),
);
