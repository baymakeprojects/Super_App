import 'package:drift/drift.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/sync/remote_store.dart';

/// Hasil satu putaran sinkron.
class SyncResult {
  const SyncResult({required this.pushed, required this.pulled, this.error});

  /// Baris lokal yang terkirim.
  final int pushed;

  /// Baris dari server yang ditulis ke HP.
  final int pulled;

  /// `null` = berhasil. Selain itu, antrean yang belum terkirim tetap ada
  /// dan dicoba lagi nanti.
  final Object? error;

  bool get ok => error == null;
}

/// Mesin sinkron offline-first (spesifikasi-teknis › Sinkron offline):
///
/// 1. **Kirim**: antrean `sync_queue` dikirim berurutan (upsert baris
///    terbaru), lalu entri yang terkirim dihapus. Gagal = berhenti, sisa
///    antrean tetap untuk dicoba lagi.
/// 2. **Tarik**: per tabel, baris server dengan `updated_at` setelah batas
///    tarikan terakhir ditulis ke HP.
/// 3. **Bentrok**: `updated_at` terbaru menang. Baris yang masih punya
///    perubahan lokal di antrean tidak ditimpa (perubahan lokal dikirim
///    di putaran berikutnya).
class SyncEngine {
  SyncEngine(this._database, this._remote, {required this.userId});

  final AppDatabase _database;
  final RemoteStore _remote;

  /// Akun Supabase yang sedang login (uuid).
  final String userId;

  /// Tabel yang disinkron, induk dulu supaya foreign key server terpenuhi.
  static const List<String> tables = [
    'profiles',
    'semesters',
    'courses',
    'class_sessions',
    'tasks',
    'subtasks',
    'wallets',
    'categories',
    'transactions',
  ];

  static const ValueSerializer _serializer = _SyncSerializer();

  /// Kirim lalu tarik. Tidak pernah melempar; kegagalan ada di
  /// [SyncResult.error].
  Future<SyncResult> sync() async {
    var pushed = 0;
    var pulled = 0;
    try {
      pushed = await push();
      pulled = await pull();
      return SyncResult(pushed: pushed, pulled: pulled);
    } on Object catch (error) {
      return SyncResult(pushed: pushed, pulled: pulled, error: error);
    }
  }

  // ---------------------------------------------------------------------------
  // Kirim
  // ---------------------------------------------------------------------------

  /// Kirim antrean. Mengembalikan jumlah baris yang terkirim.
  Future<int> push() async {
    final entries = await (_database.select(
      _database.syncQueue,
    )..orderBy([(q) => OrderingTerm(expression: q.id)])).get();
    if (entries.isEmpty) return 0;

    final lastId = entries.last.id;
    final done = <(String, String)>{};
    var pushed = 0;
    for (final entry in entries) {
      final key = (entry.targetTable, entry.rowId);
      if (!done.add(key)) continue;

      final row = await _readLocal(entry.targetTable, entry.rowId);
      if (row != null) {
        await _remote.upsert(entry.targetTable, _toRemote(row));
        pushed++;
      }
      // Semua entri baris ini sampai titik baca terkirim sekaligus (baris
      // terbaru sudah memuat semua perubahannya).
      await (_database.delete(_database.syncQueue)..where(
            (q) =>
                q.targetTable.equals(entry.targetTable) &
                q.rowId.equals(entry.rowId) &
                q.id.isSmallerOrEqualValue(lastId),
          ))
          .go();
    }
    return pushed;
  }

  Future<DataClass?> _readLocal(String table, String id) async {
    final info = _tableInfo(table);
    final rows = await _database
        .customSelect(
          'SELECT * FROM "$table" WHERE id = ?',
          variables: [Variable.withString(id)],
          readsFrom: {info},
        )
        .get();
    if (rows.isEmpty) return null;
    return await info.map(rows.single.data) as DataClass;
  }

  static Map<String, Object?> _toRemote(DataClass row) => {
    for (final MapEntry(:key, :value)
        in row.toJson(serializer: _serializer).entries)
      _snake(key): value,
  };

  // ---------------------------------------------------------------------------
  // Tarik
  // ---------------------------------------------------------------------------

  /// Tarik perubahan semua tabel. Mengembalikan jumlah baris yang ditulis.
  Future<int> pull() async {
    var pulled = 0;
    for (final table in tables) {
      pulled += await _pullTable(table);
    }
    return pulled;
  }

  Future<int> _pullTable(String table) async {
    final cursor = await (_database.select(
      _database.syncCursors,
    )..where((c) => c.syncedTable.equals(table))).getSingleOrNull();
    final rows = await _remote.fetchChanged(
      table,
      userId: userId,
      since: cursor?.pulledUntil,
    );
    if (rows.isEmpty) return 0;

    final pending = {
      for (final q in await (_database.select(
        _database.syncQueue,
      )..where((q) => q.targetTable.equals(table))).get())
        q.rowId,
    };

    var written = 0;
    DateTime? newest = cursor?.pulledUntil;
    await _database.transaction(() async {
      for (final json in rows) {
        final remote = _fromRemote(table, json);
        final remoteUpdated = DateTime.parse(json['updated_at'] as String);
        if (newest == null || remoteUpdated.isAfter(newest!)) {
          newest = remoteUpdated;
        }

        final id = json['id'] as String;
        if (pending.contains(id)) continue; // perubahan lokal belum terkirim
        final local = await _readLocal(table, id);
        if (local != null) {
          final localUpdated = DateTime.parse(
            local.toJson(serializer: _serializer)['updatedAt'] as String,
          );
          if (localUpdated.isAfter(remoteUpdated)) continue;
        }
        await _database
            .into(_tableInfo(table))
            .insertOnConflictUpdate(remote as Insertable);
        written++;
      }
      await _database
          .into(_database.syncCursors)
          .insertOnConflictUpdate(
            SyncCursorsCompanion.insert(
              syncedTable: table,
              pulledUntil: newest!,
            ),
          );
    });
    return written;
  }

  DataClass _fromRemote(String table, Map<String, dynamic> row) {
    final json = {
      for (final MapEntry(:key, :value) in row.entries) _camel(key): value,
    };
    const s = _serializer;
    return switch (table) {
      'profiles' => Profile.fromJson(json, serializer: s),
      'semesters' => Semester.fromJson(json, serializer: s),
      'courses' => Course.fromJson(json, serializer: s),
      'class_sessions' => ClassSession.fromJson(json, serializer: s),
      'tasks' => Task.fromJson(json, serializer: s),
      'subtasks' => Subtask.fromJson(json, serializer: s),
      'wallets' => Wallet.fromJson(json, serializer: s),
      'categories' => Category.fromJson(json, serializer: s),
      'transactions' => MoneyTransaction.fromJson(json, serializer: s),
      _ => throw ArgumentError.value(table, 'table', 'Tabel tidak disinkron'),
    };
  }

  TableInfo<Table, dynamic> _tableInfo(String table) =>
      _database.allTables.firstWhere((t) => t.actualTableName == table);

  // ---------------------------------------------------------------------------
  // Nama kolom: Dart camelCase ↔ Supabase snake_case
  // ---------------------------------------------------------------------------

  static String _snake(String camel) =>
      camel.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

  static String _camel(String snake) =>
      snake.replaceAllMapped(RegExp('_([a-z])'), (m) => m[1]!.toUpperCase());
}

/// Tanggal dikirim sebagai string ISO UTC (kolom `timestamptz`), dan
/// dibaca dari string ISO; nilai lain seperti bawaan drift.
class _SyncSerializer extends ValueSerializer {
  const _SyncSerializer();

  static const ValueSerializer _defaults = ValueSerializer.defaults();

  @override
  T fromJson<T>(dynamic json) {
    if (json is String && _isDateTime<T>()) {
      return DateTime.parse(json) as T;
    }
    return _defaults.fromJson<T>(json);
  }

  @override
  dynamic toJson<T>(T value) {
    if (value is DateTime) return value.toUtc().toIso8601String();
    return _defaults.toJson<T>(value);
  }

  static bool _isDateTime<T>() => <T>[] is List<DateTime?>;
}
