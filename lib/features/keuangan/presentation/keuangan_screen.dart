import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/routes.dart';
import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/core/utils/date_format.dart';
import 'package:super_app/core/utils/money_format.dart';
import 'package:super_app/features/keuangan/application/finance_snackbar.dart';
import 'package:super_app/features/keuangan/application/keuangan_providers.dart';
import 'package:super_app/features/keuangan/data/finance_repository.dart';
import 'package:super_app/features/keuangan/presentation/wallet_sheets.dart';

/// Layar 05 Keuangan versi MVP (Figma 16:300) dengan keadaan kosong E3
/// (67:2026).
///
/// Disembunyikan utuh (design-notes §7): baris chip Ringkasan/Tagihan/
/// Budget, ikon Statistik, dan bagian "Tagihan terdekat".
class KeuanganScreen extends ConsumerWidget {
  const KeuanganScreen({super.key});

  /// Ruang kosong di bawah daftar supaya baris terakhir tidak tertutup FAB.
  static const double _fabClearance = AppSpace.s20 + AppFab.size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsProvider).value;
    final now = ref.watch(clockProvider)();

    return ColoredBox(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: wallets == null
            // E7 Memuat (F-56).
            ? const AppSkeletonPage()
            : Stack(
                children: [
                  Positioned.fill(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        AppSpace.s20,
                        AppSpace.s12,
                        AppSpace.s20,
                        AppSpace.s24 + (wallets.isEmpty ? 0 : _fabClearance),
                      ),
                      children: [
                        _Header(month: AppDateFormat.monthYear(now)),
                        const SizedBox(height: AppSpace.s16),
                        if (wallets.isEmpty)
                          const _Empty()
                        else ...[
                          _TotalBalanceCard(wallets: wallets),
                          const SizedBox(height: AppSpace.s16),
                          _Wallets(wallets: wallets),
                          const _RecentTransactions(),
                        ],
                      ],
                    ),
                  ),
                  // E3 tanpa FAB: transaksi butuh dompet.
                  if (wallets.isNotEmpty) const _FabAndSnackbar(),
                ],
              ),
      ),
    );
  }
}

/// FAB Transaksi baru dan snackbar Urungkan (pola E4: snackbar 12 di atas
/// Bottom Nav, FAB 16 di atas snackbar; tanpa snackbar FAB 20 di atas).
class _FabAndSnackbar extends ConsumerWidget {
  const _FabAndSnackbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snack = ref.watch(financeSnackbarProvider);
    return Positioned(
      left: AppSpace.s20,
      right: AppSpace.s20,
      bottom: snack == null ? AppSpace.s20 : AppSpace.s12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpace.s16,
        children: [
          AppFab(
            semanticLabel: 'Transaksi baru',
            onPressed: () => context.push(AppRoutes.keuanganTransaksiBaru),
          ),
          if (snack != null)
            SizedBox(
              width: double.infinity,
              child: AppSnackbar(
                message: snack.message,
                icon: AppIcons.trash,
                iconColor: AppColors.lightGray,
                actionLabel: 'Urungkan',
                onAction: ref.read(financeSnackbarProvider.notifier).undo,
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.month});

  final String month;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.s4,
      children: [
        AppLabelText(
          month,
          style: AppText.labelSmall.copyWith(color: AppColors.gray),
        ),
        Text(
          'Keuangan',
          style: AppText.headingLarge.copyWith(color: AppColors.white),
        ),
      ],
    );
  }
}

class _TotalBalanceCard extends ConsumerWidget {
  const _TotalBalanceCard({required this.wallets});

  static const double _borderWidth = 1;

  final List<WalletBalance> wallets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = wallets.fold(0, (sum, w) => sum + w.balance);
    final summary =
        ref.watch(monthSummaryProvider).value ?? (income: 0, expense: 0);

    return Container(
      padding: const EdgeInsets.all(AppSpace.s20),
      decoration: BoxDecoration(
        gradient: AppColors.gradientBalanceCard,
        border: Border.all(color: AppColors.darkGray, width: _borderWidth),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpace.s8,
        children: [
          AppLabelText(
            'Total saldo',
            style: AppText.labelSmall.copyWith(color: AppColors.lightGray),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              AppMoneyFormat.rupiah(total),
              maxLines: 1,
              style: AppText.displayLarge.copyWith(color: AppColors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.s12),
            child: Row(
              spacing: AppSpace.s24,
              children: [
                _Flow(
                  label: 'Masuk',
                  value: AppMoneyFormat.signedCompact(
                    summary.income,
                    income: true,
                  ),
                  color: AppColors.success,
                ),
                _Flow(
                  label: 'Keluar',
                  value: AppMoneyFormat.signedCompact(
                    summary.expense,
                    income: false,
                  ),
                  color: AppColors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Flow extends StatelessWidget {
  const _Flow({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.s4,
      children: [
        AppLabelText(
          label,
          style: AppText.labelSmall.copyWith(color: AppColors.lightGray),
        ),
        Text(value, style: AppText.titleMedium.copyWith(color: color)),
      ],
    );
  }
}

/// Wallet Card berjajar. Sampai 3 dompet mengisi lebar layar seperti Figma;
/// lebih dari itu baris bisa digeser (keputusan Bayu, W3-03, F-42).
class _Wallets extends StatelessWidget {
  const _Wallets({required this.wallets});

  static const int _fitCount = 3;

  final List<WalletBalance> wallets;

  @override
  Widget build(BuildContext context) {
    final cards = [
      for (final w in wallets)
        AppWalletCard(
          label: w.wallet.name,
          amount: AppMoneyFormat.rupiah(w.balance),
        ),
    ];
    if (wallets.length <= _fitCount) {
      // Batas lebar dari Expanded mengalahkan lebar tetap 140 kartu.
      return Row(
        spacing: AppSpace.s12,
        children: [for (final card in cards) Expanded(child: card)],
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(spacing: AppSpace.s12, children: cards),
    );
  }
}

class _RecentTransactions extends ConsumerWidget {
  const _RecentTransactions();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rows = ref.watch(recentTransactionsProvider).value ?? const [];
    // Belum ada transaksi: bagian ini disembunyikan (F-42).
    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpace.s4,
        children: [
          // "Lihat semua" belum punya rute di MVP (F-42).
          const AppSectionHeader(title: 'Transaksi terakhir'),
          for (final row in rows)
            AppTransactionItem(
              key: ValueKey(row.id),
              title: row.title,
              meta: row.meta,
              amount: row.amount,
              type: row.type,
              onTap: () => context.push(AppRoutes.keuanganTransaksi(row.id)),
            ),
        ],
      ),
    );
  }
}

/// E3 Keuangan kosong: belum ada dompet.
class _Empty extends StatelessWidget {
  const _Empty();

  /// Frame "Jarak" di E3.
  static const double _spacer = 64;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: _spacer),
        AppEmptyState(
          icon: AppIcons.wallet,
          title: 'Belum ada dompet',
          message:
              'Buat dompet dulu (tunai, bank, atau e-wallet) supaya saldo '
              'dan pengeluaran bisa dihitung.',
          actionLabel: '+ Buat dompet',
          onAction: () => showNewWalletSheet(context),
          linkLabel: 'Atau isi lewat setup awal',
          onLink: () => context.push(AppRoutes.setupDompet),
        ),
      ],
    );
  }
}
