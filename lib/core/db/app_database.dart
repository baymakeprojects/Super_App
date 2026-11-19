import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:super_app/core/db/enums.dart';
import 'package:super_app/core/db/tables.dart';

part 'app_database.g.dart';

/// Database lokal (SQLite lewat drift): sumber data utama app. Layar selalu
/// membaca dari sini, bukan dari Supabase.
@DriftDatabase(
  tables: [
    Profiles,
    Semesters,
    Courses,
    ClassSessions,
    Tasks,
    Subtasks,
    Wallets,
    Categories,
    Transactions,
    SyncQueue,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// [executor] diisi di tes (misalnya database di memori).
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'super_app'));

  /// Naikkan saat struktur tabel berubah, lalu tulis langkah migrasinya.
  @override
  int get schemaVersion => 1;
}
