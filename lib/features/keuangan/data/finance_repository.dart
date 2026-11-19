import 'package:drift/drift.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/db/enums.dart';
import 'package:super_app/core/sync/sync_queue_writer.dart';
import 'package:super_app/core/utils/uuid.dart';

/// Dompet beserta saldonya sekarang.
class WalletBalance {
  const WalletBalance({required this.wallet, required this.balance});

  final Wallet wallet;

  /// Saldo awal + pemasukan − pengeluaran (transaksi yang belum dihapus).
  final int balance;
}

/// Satu transaksi siap tampil: nama dompet dan kategorinya ikut dibaca.
class TransactionListItem {
  const TransactionListItem({
    required this.transaction,
    required this.walletName,
    required this.categoryName,
  });

  final MoneyTransaction transaction;

  /// `null` kalau dompetnya sudah dihapus.
  final String? walletName;

  /// `null` = tanpa kategori, atau kategorinya sudah dihapus.
  final String? categoryName;
}

/// Ringkasan satu bulan (kartu Total saldo di 05).
typedef MonthSummary = ({int income, int expense});

/// Isi form transaksi (17 dan H11). [amount] rupiah, selalu > 0.
typedef TransactionInput = ({
  String walletId,
  String? categoryId,
  MoneyKind kind,
  int amount,
  String? notes,
  DateTime occurredAt,
});

/// Data keuangan: dompet, kategori, dan transaksi. Pola sama dengan
/// `TaskRepository`: baca disaring per akun dan `deleted_at`, tulis +
/// antrean sinkron dalam satu transaksi, hapus = soft delete.
///
/// Saldo tidak disimpan; dihitung dari saldo awal dan transaksi
/// (spesifikasi-teknis › Model data).
class FinanceRepository {
  FinanceRepository(
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

  static const String _walletsTable = 'wallets';
  static const String _categoriesTable = 'categories';
  static const String _transactionsTable = 'transactions';

  /// Kategori bawaan. Pengeluaran disalin dari chip frame 17; pemasukan
  /// belum ada di Figma (keputusan Bayu, W3-02, F-41).
  static const Map<MoneyKind, List<String>> defaultCategories = {
    MoneyKind.expense: [
      'Makan',
      'Transport',
      'Kuliah',
      'Hiburan',
      'Tagihan',
      'Lainnya',
    ],
    MoneyKind.income: ['Uang saku', 'Gaji', 'Lainnya'],
  };

  /// Urutan baris sesuai urutan dibuat (rowid SQLite), supaya kategori
  /// bawaan tampil seperti di Figma.
  static const Expression<int> _rowId = CustomExpression<int>('rowid');

  // ---------------------------------------------------------------------------
  // Dompet
  // ---------------------------------------------------------------------------

  /// Dompet yang belum dihapus beserta saldonya, urut dibuat (Tunai, Bank,
  /// E-wallet dari setup awal).
  Stream<List<WalletBalance>> watchWallets() {
    final query = _database.customSelect(
      'SELECT w.*, COALESCE(SUM(CASE '
      "WHEN t.kind = 'income' THEN t.amount "
      "WHEN t.kind = 'expense' THEN -t.amount END), 0) AS delta "
      'FROM wallets w '
      'LEFT JOIN transactions t ON t.wallet_id = w.id '
      'AND t.user_id = w.user_id AND t.deleted_at IS NULL '
      'WHERE w.user_id = ? AND w.deleted_at IS NULL '
      'GROUP BY w.id ORDER BY w.rowid',
      variables: [Variable.withString(userId)],
      readsFrom: {_database.wallets, _database.transactions},
    );
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          () {
            final wallet = _database.wallets.map(row.data);
            return WalletBalance(
              wallet: wallet,
              balance: wallet.openingBalance + row.read<int>('delta'),
            );
          }(),
      ],
    );
  }

  /// Total saldo semua dompet (kartu Total saldo di 05).
  Stream<int> watchTotalBalance() => watchWallets().map(
    (wallets) => wallets.fold(0, (sum, w) => sum + w.balance),
  );

  /// Dompet sekali baca (pilihan P06).
  Future<List<Wallet>> getWallets() {
    final query = _database.select(_database.wallets)
      ..where((w) => w.userId.equals(userId) & w.deletedAt.isNull())
      ..orderBy([(w) => OrderingTerm(expression: _rowId)]);
    return query.get();
  }

  /// Menambah dompet (P07, setup awal 01b). Mengembalikan id.
  Future<String> addWallet({
    required String name,
    required WalletKind kind,
    int openingBalance = 0,
  }) {
    return _database.transaction(() async {
      final id = _newId();
      final now = _now();
      await _database
          .into(_database.wallets)
          .insert(
            WalletsCompanion.insert(
              id: id,
              userId: userId,
              name: name,
              kind: kind,
              openingBalance: Value(openingBalance),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      await _queue.enqueue(
        table: _walletsTable,
        rowId: id,
        operation: SyncOperation.insert,
      );
      return id;
    });
  }

  // ---------------------------------------------------------------------------
  // Kategori
  // ---------------------------------------------------------------------------

  SimpleSelectStatement<$CategoriesTable, Category> _categoriesQuery(
    MoneyKind kind,
  ) {
    return _database.select(_database.categories)
      ..where(
        (c) =>
            c.userId.equals(userId) &
            c.kind.equalsValue(kind) &
            c.deletedAt.isNull(),
      )
      ..orderBy([(c) => OrderingTerm(expression: _rowId)]);
  }

  /// Kategori satu arah uang (chip Kategori di 17).
  Stream<List<Category>> watchCategories(MoneyKind kind) =>
      _categoriesQuery(kind).watch();

  Future<List<Category>> getCategories(MoneyKind kind) =>
      _categoriesQuery(kind).get();

  /// Buat kategori bawaan kalau akun ini belum punya kategori sama sekali
  /// (termasuk yang sudah dihapus, supaya kategori yang sengaja dihapus
  /// tidak muncul lagi). Aman dipanggil berkali-kali.
  Future<void> ensureDefaultCategories() {
    return _database.transaction(() async {
      final existing =
          await (_database.select(_database.categories)
                ..where((c) => c.userId.equals(userId))
                ..limit(1))
              .get();
      if (existing.isNotEmpty) return;

      final now = _now();
      for (final MapEntry(key: kind, value: names)
          in defaultCategories.entries) {
        for (final name in names) {
          final id = _newId();
          await _database
              .into(_database.categories)
              .insert(
                CategoriesCompanion.insert(
                  id: id,
                  userId: userId,
                  name: name,
                  kind: kind,
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ),
              );
          await _queue.enqueue(
            table: _categoriesTable,
            rowId: id,
            operation: SyncOperation.insert,
          );
        }
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Transaksi: baca
  // ---------------------------------------------------------------------------

  JoinedSelectStatement<HasResultSet, dynamic> _listQuery() {
    final t = _database.transactions;
    final w = _database.wallets;
    final c = _database.categories;
    return _database.select(t).join([
        leftOuterJoin(
          w,
          w.id.equalsExp(t.walletId) &
              w.userId.equalsExp(t.userId) &
              w.deletedAt.isNull(),
        ),
        leftOuterJoin(
          c,
          c.id.equalsExp(t.categoryId) &
              c.userId.equalsExp(t.userId) &
              c.deletedAt.isNull(),
        ),
      ])
      ..where(t.userId.equals(userId) & t.deletedAt.isNull())
      ..orderBy([
        OrderingTerm(expression: t.occurredAt, mode: OrderingMode.desc),
        OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ]);
  }

  List<TransactionListItem> _toItems(List<TypedResult> rows) => [
    for (final row in rows)
      TransactionListItem(
        transaction: row.readTable(_database.transactions),
        walletName: row.readTableOrNull(_database.wallets)?.name,
        categoryName: row.readTableOrNull(_database.categories)?.name,
      ),
  ];

  /// Transaksi terbaru dulu (Transaksi terakhir di 05 dan 02).
  Stream<List<TransactionListItem>> watchRecentTransactions({int? limit}) {
    final query = _listQuery();
    if (limit != null) query.limit(limit);
    return query.watch().map(_toItems);
  }

  /// Satu transaksi (isian awal H11). `null` = tidak ada atau dihapus.
  Future<TransactionListItem?> getTransaction(String id) async {
    final query = _listQuery()..where(_database.transactions.id.equals(id));
    final items = _toItems(await query.get());
    return items.isEmpty ? null : items.single;
  }

  /// Total masuk dan keluar bulan [month] (tanggal mana saja di bulan itu,
  /// waktu HP).
  Stream<MonthSummary> watchMonthSummary(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final t = _database.transactions;
    final total = t.amount.sum();
    final query = _database.selectOnly(t)
      ..addColumns([t.kind, total])
      ..where(
        t.userId.equals(userId) &
            t.deletedAt.isNull() &
            t.occurredAt.isBiggerOrEqualValue(start) &
            t.occurredAt.isSmallerThanValue(end),
      )
      ..groupBy([t.kind]);
    return query.watch().map((rows) {
      var income = 0;
      var expense = 0;
      for (final row in rows) {
        final amount = row.read(total) ?? 0;
        switch (row.readWithConverter<MoneyKind?, String>(t.kind)) {
          case MoneyKind.income:
            income = amount;
          case MoneyKind.expense:
            expense = amount;
          case null:
            break;
        }
      }
      return (income: income, expense: expense);
    });
  }

  // ---------------------------------------------------------------------------
  // Transaksi: tulis
  // ---------------------------------------------------------------------------

  /// Menambah transaksi (17). Mengembalikan id.
  Future<String> addTransaction(TransactionInput input) {
    _checkAmount(input.amount);
    return _database.transaction(() async {
      final id = _newId();
      final now = _now();
      await _database
          .into(_database.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: id,
              userId: userId,
              walletId: input.walletId,
              categoryId: Value(input.categoryId),
              kind: input.kind,
              amount: input.amount,
              notes: Value(input.notes),
              occurredAt: input.occurredAt,
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      await _queue.enqueue(
        table: _transactionsTable,
        rowId: id,
        operation: SyncOperation.insert,
      );
      return id;
    });
  }

  /// Mengubah transaksi (H11).
  Future<void> updateTransaction(String id, TransactionInput input) {
    _checkAmount(input.amount);
    return _writeTransaction(
      id,
      TransactionsCompanion(
        walletId: Value(input.walletId),
        categoryId: Value(input.categoryId),
        kind: Value(input.kind),
        amount: Value(input.amount),
        notes: Value(input.notes),
        occurredAt: Value(input.occurredAt),
      ),
      SyncOperation.update,
    );
  }

  /// Menghapus transaksi (soft delete, P47).
  Future<void> deleteTransaction(String id) => _writeTransaction(
    id,
    TransactionsCompanion(deletedAt: Value(_now())),
    SyncOperation.delete,
  );

  /// Urungkan hapus (snackbar E4).
  Future<void> restoreTransaction(String id) => _writeTransaction(
    id,
    const TransactionsCompanion(deletedAt: Value(null)),
    SyncOperation.update,
  );

  Future<void> _writeTransaction(
    String id,
    TransactionsCompanion changes,
    SyncOperation operation,
  ) {
    return _database.transaction(() async {
      final changed =
          await (_database.update(_database.transactions)
                ..where((t) => t.userId.equals(userId) & t.id.equals(id)))
              .write(changes.copyWith(updatedAt: Value(_now())));
      if (changed == 0) throw StateError('Transaksi $id tidak ditemukan');
      await _queue.enqueue(
        table: _transactionsTable,
        rowId: id,
        operation: operation,
      );
    });
  }

  static void _checkAmount(int amount) {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'Nominal harus lebih dari 0');
    }
  }
}
