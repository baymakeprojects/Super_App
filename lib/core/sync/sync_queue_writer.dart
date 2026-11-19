import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/db/enums.dart';

/// Mencatat perubahan ke `sync_queue` supaya nanti dikirim ke Supabase.
///
/// Selalu dipanggil **di dalam** `database.transaction(...)` milik
/// repository, bersama penulisan barisnya: keduanya tersimpan atau
/// keduanya batal.
class SyncQueueWriter {
  SyncQueueWriter(this._database, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _database;
  final DateTime Function() _now;

  Future<void> enqueue({
    required String table,
    required String rowId,
    required SyncOperation operation,
  }) {
    return _database
        .into(_database.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            targetTable: table,
            rowId: rowId,
            operation: operation,
            createdAt: _now(),
          ),
        );
  }
}
