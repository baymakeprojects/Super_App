import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/db/enums.dart';
import 'package:super_app/features/keuangan/data/finance_repository.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late FinanceRepository repository;
  late DateTime now;
  var counter = 0;

  FinanceRepository build(String userId) => FinanceRepository(
    db,
    userId: userId,
    now: () => now,
    newId: () => 'id-${++counter}',
  );

  setUp(() {
    db = testDatabase();
    now = DateTime(2026, 11, 6, 7, 10);
    counter = 0;
    repository = build('user-a');
  });

  tearDown(() => db.close());

  Future<List<SyncQueueEntry>> queue() => (db.select(
    db.syncQueue,
  )..orderBy([(q) => OrderingTerm(expression: q.id)])).get();

  TransactionInput input(
    String walletId,
    MoneyKind kind,
    int amount, {
    DateTime? at,
    String? categoryId,
  }) => (
    walletId: walletId,
    categoryId: categoryId,
    kind: kind,
    amount: amount,
    notes: null,
    occurredAt: at ?? now,
  );

  group('dompet dan saldo', () {
    test('saldo = saldo awal + pemasukan − pengeluaran', () async {
      final tunai = await repository.addWallet(
        name: 'Tunai',
        kind: WalletKind.cash,
        openingBalance: 150000,
      );
      final bank = await repository.addWallet(
        name: 'Bank',
        kind: WalletKind.bank,
        openingBalance: 900000,
      );
      await repository.addTransaction(input(tunai, MoneyKind.expense, 15000));
      await repository.addTransaction(input(bank, MoneyKind.income, 500000));
      final hapus = await repository.addTransaction(
        input(bank, MoneyKind.expense, 99000),
      );
      await repository.deleteTransaction(hapus);

      final wallets = await repository.watchWallets().first;
      expect(wallets.map((w) => (w.wallet.name, w.balance)), [
        ('Tunai', 135000),
        ('Bank', 1400000),
      ]);
      expect(await repository.watchTotalBalance().first, 1535000);
    });

    test('dompet akun lain tidak terbaca', () async {
      await build('user-b').addWallet(name: 'Milik B', kind: WalletKind.cash);
      expect(await repository.getWallets(), isEmpty);
      expect(await repository.watchTotalBalance().first, 0);
    });
  });

  group('ringkasan bulan', () {
    test('hanya transaksi bulan itu yang belum dihapus', () async {
      final w = await repository.addWallet(
        name: 'Tunai',
        kind: WalletKind.cash,
      );
      await repository.addTransaction(
        input(w, MoneyKind.income, 2000000, at: DateTime(2026, 11, 1)),
      );
      await repository.addTransaction(
        input(w, MoneyKind.expense, 500000, at: DateTime(2026, 11, 30, 23, 59)),
      );
      await repository.addTransaction(
        input(w, MoneyKind.expense, 250000, at: DateTime(2026, 11, 6)),
      );
      // Bulan lain.
      await repository.addTransaction(
        input(w, MoneyKind.expense, 1, at: DateTime(2026, 10, 31, 23, 59)),
      );
      await repository.addTransaction(
        input(w, MoneyKind.income, 1, at: DateTime(2026, 12)),
      );

      final summary = await repository
          .watchMonthSummary(DateTime(2026, 11, 19))
          .first;
      expect(summary, (income: 2000000, expense: 750000));
    });

    test('bulan kosong = nol', () async {
      final summary = await repository.watchMonthSummary(now).first;
      expect(summary, (income: 0, expense: 0));
    });
  });

  group('kategori bawaan', () {
    test('dibuat sekali, urut seperti chip 17', () async {
      await repository.ensureDefaultCategories();
      await repository.ensureDefaultCategories();

      final expense = await repository.getCategories(MoneyKind.expense);
      expect(expense.map((c) => c.name), [
        'Makan',
        'Transport',
        'Kuliah',
        'Hiburan',
        'Tagihan',
        'Lainnya',
      ]);
      final income = await repository.getCategories(MoneyKind.income);
      expect(income.map((c) => c.name), ['Uang saku', 'Gaji', 'Lainnya']);
      expect((await queue()).length, 9);
    });

    test('akun yang sudah punya kategori tidak ditambah', () async {
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'k1',
              userId: 'user-a',
              name: 'Kopi',
              kind: MoneyKind.expense,
            ),
          );
      await repository.ensureDefaultCategories();
      final expense = await repository.getCategories(MoneyKind.expense);
      expect(expense.map((c) => c.name), ['Kopi']);
    });
  });

  group('transaksi', () {
    test('daftar terbaru dulu, dengan nama dompet dan kategori', () async {
      await repository.ensureDefaultCategories();
      final makan = (await repository.getCategories(MoneyKind.expense)).first;
      final w = await repository.addWallet(
        name: 'Tunai',
        kind: WalletKind.cash,
      );
      await repository.addTransaction(
        input(
          w,
          MoneyKind.expense,
          15000,
          at: DateTime(2026, 11, 6, 7, 10),
          categoryId: makan.id,
        ),
      );
      await repository.addTransaction(
        input(w, MoneyKind.income, 1500000, at: DateTime(2026, 11)),
      );

      final items = await repository.watchRecentTransactions(limit: 5).first;
      expect(
        items.map((i) => (i.transaction.amount, i.walletName, i.categoryName)),
        [(15000, 'Tunai', 'Makan'), (1500000, 'Tunai', null)],
      );
      final limited = await repository.watchRecentTransactions(limit: 1).first;
      expect(limited, hasLength(1));
    });

    test('ubah, hapus, dan urungkan tercatat di antrean', () async {
      final w = await repository.addWallet(
        name: 'Tunai',
        kind: WalletKind.cash,
      );
      final id = await repository.addTransaction(
        input(w, MoneyKind.expense, 15000),
      );
      await repository.updateTransaction(
        id,
        input(w, MoneyKind.expense, 20000),
      );
      expect((await repository.getTransaction(id))!.transaction.amount, 20000);

      await repository.deleteTransaction(id);
      expect(await repository.getTransaction(id), isNull);
      await repository.restoreTransaction(id);
      expect(await repository.getTransaction(id), isNotNull);

      final ops = (await queue())
          .where((q) => q.targetTable == 'transactions')
          .map((q) => q.operation);
      expect(ops, [
        SyncOperation.insert,
        SyncOperation.update,
        SyncOperation.delete,
        SyncOperation.update,
      ]);
    });

    test('nominal harus lebih dari 0', () async {
      final w = await repository.addWallet(
        name: 'Tunai',
        kind: WalletKind.cash,
      );
      expect(
        () => repository.addTransaction(input(w, MoneyKind.expense, 0)),
        throwsArgumentError,
      );
    });

    test('transaksi akun lain tidak bisa diubah', () async {
      final other = build('user-b');
      final w = await other.addWallet(name: 'B', kind: WalletKind.cash);
      final id = await other.addTransaction(input(w, MoneyKind.expense, 1));
      await expectLater(repository.deleteTransaction(id), throwsStateError);
    });
  });
}
