import 'package:drift/drift.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/db/enums.dart';
import 'package:super_app/core/sync/sync_queue_writer.dart';
import 'package:super_app/core/utils/uuid.dart';

/// Data semester. Pola sama dengan `TaskRepository`: baca disaring per akun
/// dan `deleted_at`, tulis + antrean sinkron dalam satu transaksi.
///
/// Hanya satu semester yang aktif; jadwal (04) dan mata kuliah baru ikut
/// semester aktif.
class SemesterRepository {
  SemesterRepository(
    this._database, {
    required this.userId,
    SyncQueueWriter? queue,
    DateTime Function()? now,
    String Function()? newId,
  }) : _queue = queue ?? SyncQueueWriter(_database, now: now),
       _now = now ?? DateTime.now,
       _newId = newId ?? newUuidV4;

  final AppDatabase _database;
  final SyncQueueWriter _queue;
  final DateTime Function() _now;
  final String Function() _newId;

  /// Pemilik data (akun yang sedang login).
  final String userId;

  static const String _table = 'semesters';

  SimpleSelectStatement<$SemestersTable, Semester> _activeQuery() {
    return _database.select(_database.semesters)
      ..where(
        (s) =>
            s.userId.equals(userId) &
            s.isActive.equals(true) &
            s.deletedAt.isNull(),
      )
      ..limit(1);
  }

  /// Semester aktif, `null` kalau belum ada.
  Stream<Semester?> watchActiveSemester() => _activeQuery().watchSingleOrNull();

  Future<Semester?> getActiveSemester() => _activeQuery().getSingleOrNull();

  /// Semua semester yang belum dihapus, yang terbaru dulu.
  Future<List<Semester>> getSemesters() {
    final query = _database.select(_database.semesters)
      ..where((s) => s.userId.equals(userId) & s.deletedAt.isNull())
      ..orderBy([
        (s) => OrderingTerm(
          expression: s.startsOn,
          mode: OrderingMode.desc,
          nulls: NullsOrder.last,
        ),
      ]);
    return query.get();
  }

  /// Menambah semester. [active] = langsung jadi semester aktif.
  Future<String> addSemester({
    required String name,
    DateTime? startsOn,
    DateTime? endsOn,
    bool active = false,
  }) {
    return _database.transaction(() async {
      final id = _newId();
      final now = _now();
      await _database
          .into(_database.semesters)
          .insert(
            SemestersCompanion.insert(
              id: id,
              userId: userId,
              name: name,
              startsOn: Value(startsOn),
              endsOn: Value(endsOn),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      await _queue.enqueue(
        table: _table,
        rowId: id,
        operation: SyncOperation.insert,
      );
      if (active) await setActiveSemester(id);
      return id;
    });
  }

  /// Menjadikan [id] semester aktif; semester aktif sebelumnya dinonaktifkan.
  Future<void> setActiveSemester(String id) {
    return _database.transaction(() async {
      final semesters = _database.semesters;
      final current = await getActiveSemester();
      if (current?.id == id) return;
      if (current != null) {
        await _write(
          current.id,
          const SemestersCompanion(isActive: Value(false)),
        );
      }
      final target =
          await (_database.select(semesters)..where(
                (s) =>
                    s.userId.equals(userId) &
                    s.id.equals(id) &
                    s.deletedAt.isNull(),
              ))
              .getSingleOrNull();
      if (target == null) throw StateError('Semester $id tidak ditemukan');
      await _write(id, const SemestersCompanion(isActive: Value(true)));
    });
  }

  Future<void> _write(String id, SemestersCompanion changes) async {
    await (_database.update(_database.semesters)
          ..where((s) => s.userId.equals(userId) & s.id.equals(id)))
        .write(changes.copyWith(updatedAt: Value(_now())));
    await _queue.enqueue(
      table: _table,
      rowId: id,
      operation: SyncOperation.update,
    );
  }
}
