import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:super_app/core/db/enums.dart';
import 'package:super_app/core/ui/app_transaction_item.dart';
import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/core/utils/date_format.dart';
import 'package:super_app/core/utils/money_format.dart';
import 'package:super_app/features/keuangan/data/finance_repository.dart';
import 'package:super_app/features/keuangan/data/finance_repository_provider.dart';

/// Dompet beserta saldonya (05, P06).
final walletsProvider = StreamProvider<List<WalletBalance>>(
  (ref) => ref.watch(financeRepositoryProvider).watchWallets(),
);

/// Masuk dan keluar bulan ini (kartu Total saldo di 05).
final monthSummaryProvider = StreamProvider<MonthSummary>((ref) {
  final now = ref.watch(clockProvider)();
  return ref.watch(financeRepositoryProvider).watchMonthSummary(now);
});

/// Jumlah transaksi di "Transaksi terakhir" 05 (keputusan Bayu, W3-03,
/// F-42; Figma memperlihatkan 2 contoh).
const int recentTransactionLimit = 5;

/// Transaksi terakhir di 05.
final recentTransactionsProvider = StreamProvider<List<TransactionRow>>((ref) {
  final now = ref.watch(clockProvider)();
  return ref
      .watch(financeRepositoryProvider)
      .watchRecentTransactions(limit: recentTransactionLimit)
      .map((items) => [for (final item in items) transactionRowOf(item, now)]);
});

/// Satu Transaction Item siap tampil.
class TransactionRow {
  const TransactionRow({
    required this.id,
    required this.title,
    required this.meta,
    required this.amount,
    required this.type,
  });

  final String id;
  final String title;
  final String meta;
  final String amount;
  final AppTransactionType type;
}

/// Aturan baris transaksi (05, 02), keputusan Bayu W3-03 (F-42):
///
/// - Judul: catatan; kalau kosong, nama kategori; kalau tidak ada juga,
///   "Pemasukan" / "Pengeluaran".
/// - Meta: dompet · kategori (atau "Pemasukan"/"Pengeluaran") · jam kalau
///   hari ini, tanggal kalau bukan ("Tunai · Makan · 07.10",
///   "Bank · Pemasukan · 1 Nov" seperti Figma).
/// - Nominal: "−Rp15.000" / "+Rp1.500.000".
TransactionRow transactionRowOf(TransactionListItem item, DateTime now) {
  final t = item.transaction;
  final income = t.kind == MoneyKind.income;
  final kindLabel = income ? 'Pemasukan' : 'Pengeluaran';
  final at = t.occurredAt.toLocal();
  final when = AppDateFormat.daysBetween(now, at) == 0
      ? AppDateFormat.time(at)
      : AppDateFormat.dayMonthShort(at);
  final notes = t.notes?.trim();

  return TransactionRow(
    id: t.id,
    title: (notes != null && notes.isNotEmpty)
        ? notes
        : item.categoryName ?? kindLabel,
    meta: [?item.walletName, item.categoryName ?? kindLabel, when].join(' · '),
    amount: AppMoneyFormat.signed(t.amount, income: income),
    type: income ? AppTransactionType.income : AppTransactionType.expense,
  );
}
