import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:super_app/core/db/app_database.dart';

/// Satu database untuk seluruh app; ditutup saat provider dibuang.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
