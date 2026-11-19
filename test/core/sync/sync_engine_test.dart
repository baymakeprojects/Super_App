import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/db/database_provider.dart';
import 'package:super_app/core/db/enums.dart';
import 'package:super_app/core/sync/remote_store.dart';
import 'package:super_app/core/sync/sync_controller.dart';
import 'package:super_app/core/sync/sync_engine.dart';
import 'package:super_app/features/keuangan/data/finance_repository.dart';
import 'package:super_app/features/tugas/data/task_repository.dart';

import '../../helpers/test_database.dart';

const String _user = '11111111-1111-4111-8111-111111111111';

/// Server palsu di memori: bisa dibuat offline, menyimpan baris per tabel
/// seperti Supabase (kolom snake_case, tanggal string ISO).
class FakeRemoteStore implements RemoteStore {
  final Map<String, Map<String, Map<String, dynamic>>> tables = {};
  bool offline = false;

  Map<String, Map<String, dynamic>> table(String name) =>
      tables.putIfAbsent(name, () => {});

  void _check() {
    if (offline) throw StateError('offline');
  }

  @override
  Future<void> upsert(String table, Map<String, Object?> row) async {
    _check();
    this.table(table)[row['id']! as String] = Map.of(row);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchChanged(
    String table, {
    required String userId,
    DateTime? since,
  }) async {
    _check();
    final rows =
        this
            .table(table)
            .values
            .where((r) => r['user_id'] == userId)
            .where(
              (r) =>
                  since == null ||
                  DateTime.parse(r['updated_at'] as String).isAfter(since),
            )
            .toList()
          ..sort(
            (a, b) => (a['updated_at'] as String).compareTo(
              b['updated_at'] as String,
            ),
          );
    return rows;
  }
}

void main() {
  late AppDatabase db;
  late FakeRemoteStore remote;
  late SyncEngine engine;
  late DateTime now;

  setUp(() {
    db = testDatabase();
    remote = FakeRemoteStore();
    engine = SyncEngine(db, remote, userId: _user);
    now = DateTime.utc(2026, 11, 6, 7, 10);
  });

  tearDown(() => db.close());

  TaskRepository tasks() => TaskRepository(db, userId: _user, now: () => now);

  Future<int> queueLength() async =>
      (await db.select(db.syncQueue).get()).length;

  group('offline → online', () {
    test('offline: gagal, antrean utuh; online: semua terkirim', () async {
      final id = await tasks().addTask(
        title: 'Laporan praktikum',
        dueAt: DateTime.utc(2026, 11, 6, 23, 59),
        priority: TaskPriority.medium,
        subtasks: ['Kode', 'Analisis'],
      );
      final finance = FinanceRepository(db, userId: _user, now: () => now);
      final wallet = await finance.addWallet(
        name: 'Tunai',
        kind: WalletKind.cash,
        openingBalance: 150000,
      );
      await finance.addTransaction((
        walletId: wallet,
        categoryId: null,
        kind: MoneyKind.expense,
        amount: 15000,
        notes: 'Sarapan',
        occurredAt: now,
      ));
      await tasks().setDone(id, done: true);
      final before = await queueLength();
      expect(before, greaterThan(0));

      remote.offline = true;
      final failed = await engine.sync();
      expect(failed.ok, isFalse);
      expect(await queueLength(), before);

      remote.offline = false;
      final ok = await engine.sync();
      expect(ok.ok, isTrue);
      expect(await queueLength(), 0);
      // Tugas, 2 sub-tugas, dompet, transaksi (tugas dikirim sekali saja
      // meskipun ada di antrean dua kali).
      expect(ok.pushed, 5);

      final task = remote.table('tasks')[id]!;
      expect(task['user_id'], _user);
      expect(task['title'], 'Laporan praktikum');
      expect(task['status'], 'done');
      expect(task['priority'], 'medium');
      expect(task['due_at'], '2026-11-06T23:59:00.000Z');
      expect(remote.table('subtasks'), hasLength(2));
      final tx = remote.table('transactions').values.single;
      expect(
        (tx['amount'], tx['kind'], tx['wallet_id']),
        (15000, 'expense', wallet),
      );
      expect(remote.table('wallets')[wallet]!['opening_balance'], 150000);
    });

    test('hapus (soft delete) ikut terkirim', () async {
      final id = await tasks().addTask(title: 'Kuis');
      await engine.sync();
      now = now.add(const Duration(minutes: 1));
      await tasks().deleteTask(id);
      await engine.sync();
      expect(remote.table('tasks')[id]!['deleted_at'], isNotNull);
    });
  });

  group('tarik', () {
    Map<String, dynamic> remoteTask(String id, String title, String updated) =>
        {
          'id': id,
          'user_id': _user,
          'course_id': null,
          'title': title,
          'notes': null,
          'due_at': '2026-11-09T03:00:00+00:00',
          'priority': 'high',
          'status': 'active',
          'completed_at': null,
          'created_at': '2026-11-05T01:00:00+00:00',
          'updated_at': updated,
          'deleted_at': null,
        };

    test(
      'perubahan dari perangkat lain masuk; tarikan berikut tidak ulang',
      () async {
        remote.table('tasks')['t9'] = remoteTask(
          't9',
          'Dari desktop',
          '2026-11-05T02:00:00+00:00',
        );
        // Baris akun lain tidak ikut.
        remote.table('tasks')['x1'] = {
          ...remoteTask('x1', 'Milik orang lain', '2026-11-05T02:00:00+00:00'),
          'user_id': 'akun-lain',
        };

        final first = await engine.sync();
        expect(first.pulled, 1);
        final local = await tasks().getTask('t9');
        expect(local!.title, 'Dari desktop');
        expect(local.priority, TaskPriority.high);
        expect(local.dueAt, DateTime.utc(2026, 11, 9, 3));

        final second = await engine.sync();
        expect(second.pulled, 0);
      },
    );

    test(
      'bentrok: yang terbaru menang, perubahan lokal tertunda aman',
      () async {
        final id = await tasks().addTask(title: 'Versi HP');
        await engine.sync();

        // Server lebih baru → menimpa HP.
        remote.table('tasks')[id] = {
          ...remote.table('tasks')[id]!,
          'title': 'Versi desktop',
          'updated_at': '2026-11-06T08:00:00+00:00',
        };
        await engine.sync();
        expect((await tasks().getTask(id))!.title, 'Versi desktop');

        // Perubahan lokal belum terkirim tidak ditimpa tarikan, lalu terkirim.
        remote.offline = true;
        now = DateTime.utc(2026, 11, 6, 9);
        await tasks().updateTask(id, title: 'Diubah offline');
        remote.offline = false;
        remote.table('tasks')[id] = {
          ...remote.table('tasks')[id]!,
          'title': 'Versi lama server',
          'updated_at': '2026-11-06T08:30:00+00:00',
        };
        await engine.sync();
        expect((await tasks().getTask(id))!.title, 'Diubah offline');
        expect(remote.table('tasks')[id]!['title'], 'Diubah offline');
      },
    );
  });

  group('pengendali', () {
    test('jeda coba ulang 30 detik, berlipat, maks 15 menit', () {
      expect(retryDelay(1), const Duration(seconds: 30));
      expect(retryDelay(2), const Duration(minutes: 1));
      expect(retryDelay(3), const Duration(minutes: 2));
      expect(retryDelay(10), const Duration(minutes: 15));
    });

    test('belum login: sinkron mati', () {
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
      expect(container.read(syncControllerProvider).phase, SyncPhase.disabled);
    });

    test('gagal lalu berhasil mengubah status', () async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          remoteStoreProvider.overrideWithValue(remote),
          syncUserIdProvider.overrideWithValue(_user),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(syncControllerProvider.notifier);
      await tasks().addTask(title: 'Kuis');

      remote.offline = true;
      await controller.syncNow();
      var state = container.read(syncControllerProvider);
      expect((state.phase, state.failures), (SyncPhase.failed, 1));

      remote.offline = false;
      await controller.syncNow();
      state = container.read(syncControllerProvider);
      expect((state.phase, state.failures), (SyncPhase.synced, 0));
      expect(remote.table('tasks'), hasLength(1));
    });
  });
}
