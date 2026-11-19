import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/routes.dart';
import 'package:super_app/core/sync/sync_status_banner.dart';
import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/core/utils/date_format.dart';
import 'package:super_app/core/utils/money_format.dart';
import 'package:super_app/features/beranda/application/beranda_providers.dart';
import 'package:super_app/features/beranda/application/beranda_view.dart';
import 'package:super_app/features/keuangan/application/keuangan_providers.dart';
import 'package:super_app/features/tugas/application/task_list_providers.dart';
import 'package:super_app/features/tugas/application/task_list_view.dart';
import 'package:super_app/features/tugas/data/task_repository_provider.dart';

/// Layar 02 Beranda (Figma 13:14) dengan data asli.
///
/// Ikon Notifikasi (Tahap 2) disembunyikan (design-notes §7). Beranda
/// kosong E1 dibuat di W4-02; sampai itu bagian tanpa data disembunyikan
/// (keputusan Bayu, W3-06, F-45).
class BerandaScreen extends ConsumerWidget {
  const BerandaScreen({super.key});

  /// Jumlah baris "Tugas hari ini" dan "Transaksi terakhir" (Figma: 2).
  static const int _taskLimit = 3;
  static const int _transactionLimit = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final name = ref.watch(profileNameProvider).value;
    final nextClass = ref.watch(nextClassProvider);
    // Selalu aturan filter Semua, apa pun filter yang dipilih di 03.
    final taskView = buildTaskListView(
      ref.watch(taskListItemsProvider).value ?? const [],
      TaskFilter.semua,
      now,
    );
    final transactions =
        ref.watch(recentTransactionsProvider).value ?? const [];

    final todayRows = [
      for (final group in taskView.groups)
        if (group.kind == TaskGroupKind.hariIni) ...group.rows,
    ];

    return ColoredBox(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.s20,
            AppSpace.s12,
            AppSpace.s20,
            AppSpace.s24,
          ),
          children: [
            _Header(
              date: AppDateFormat.weekdayCommaDayMonthLong(now),
              name: name,
            ),
            // E5 offline / G8 sinkron gagal: di bawah header, di atas isi.
            const SyncStatusBanner(spacing: AppSpace.s24),
            if (nextClass != null) ...[
              const SizedBox(height: AppSpace.s24),
              _NextClassCard(next: nextClass),
            ],
            const SizedBox(height: AppSpace.s24),
            const _Stats(),
            if (todayRows.isNotEmpty) ...[
              const SizedBox(height: AppSpace.s24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpace.s12,
                children: [
                  AppSectionHeader(
                    title: 'Tugas hari ini',
                    actionLabel: 'Lihat semua →',
                    onActionPressed: () => context.go(AppRoutes.tugas),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    spacing: AppSpace.s8,
                    children: [
                      for (final row in todayRows.take(_taskLimit))
                        AppTaskItem(
                          key: ValueKey(row.id),
                          title: row.title,
                          meta: row.meta,
                          done: row.done,
                          badge: row.badgeLabel == null
                              ? null
                              : AppBadge(
                                  label: row.badgeLabel!,
                                  type: row.badgeType,
                                ),
                          // Snackbar Urungkan hanya di 03; di sini tugas
                          // langsung selesai (sama dengan layar 20, F-40).
                          onDoneChanged: (done) => ref
                              .read(taskRepositoryProvider)
                              .setDone(row.id, done: done),
                          onTap: () =>
                              context.push(AppRoutes.tugasDetail(row.id)),
                        ),
                    ],
                  ),
                ],
              ),
            ],
            if (transactions.isNotEmpty) ...[
              const SizedBox(height: AppSpace.s24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpace.s4,
                children: [
                  AppSectionHeader(
                    title: 'Transaksi terakhir',
                    actionLabel: 'Lihat semua →',
                    onActionPressed: () => context.go(AppRoutes.keuangan),
                  ),
                  for (final row in transactions.take(_transactionLimit))
                    AppTransactionItem(
                      key: ValueKey(row.id),
                      title: row.title,
                      meta: row.meta,
                      amount: row.amount,
                      type: row.type,
                      onTap: () =>
                          context.push(AppRoutes.keuanganTransaksi(row.id)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.date, required this.name});

  // Ukuran tetap dari Figma (bukan variabel Figma): lingkaran avatar.
  static const double _avatarSize = 40;
  static const double _avatarIconSize = 20;

  final String date;

  /// `null` = belum ada nama: "Halo" dan avatar berikon User (F-45).
  final String? name;

  @override
  Widget build(BuildContext context) {
    final name = this.name;
    final initial = initialOf(name);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.s4,
            children: [
              AppLabelText(
                date,
                style: AppText.labelSmall.copyWith(color: AppColors.gray),
              ),
              Text(
                name == null ? 'Halo' : 'Halo, $name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.headingLarge.copyWith(color: AppColors.white),
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: 'Pengaturan',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push(AppRoutes.pengaturan),
            child: Container(
              width: _avatarSize,
              height: _avatarSize,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.brandingOrange,
                shape: BoxShape.circle,
              ),
              child: initial == null
                  ? const AppIcon(
                      AppIcons.user,
                      size: _avatarIconSize,
                      color: AppColors.onAccent,
                    )
                  : AppLabelText(
                      initial,
                      style: AppText.labelLarge.copyWith(
                        color: AppColors.onAccent,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Kartu oranye "Kelas berikutnya" (Figma 13:37).
class _NextClassCard extends StatelessWidget {
  const _NextClassCard({required this.next});

  static const double _iconSize = 20;

  final NextClass next;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push(AppRoutes.kuliahDetail(next.courseId)),
        child: Container(
          padding: const EdgeInsets.all(AppSpace.s20),
          decoration: BoxDecoration(
            color: AppColors.brandingOrange,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.s8,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppLabelText(
                      'Kelas berikutnya · ${next.countdown}',
                      style: AppText.labelSmall.copyWith(
                        color: AppColors.onAccent,
                      ),
                    ),
                  ),
                  const AppIcon(
                    AppIcons.arrowUpRight,
                    size: _iconSize,
                    color: AppColors.onAccent,
                  ),
                ],
              ),
              Text(
                next.course,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.headingMedium.copyWith(
                  color: AppColors.onAccent,
                ),
              ),
              Text(
                next.meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodyMedium.copyWith(color: AppColors.onAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stat Card Tugas aktif dan Saldo.
class _Stats extends ConsumerWidget {
  const _Stats();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(taskListItemsProvider).value ?? const [];
    final now = ref.watch(clockProvider)();
    final view = buildTaskListView(items, TaskFilter.semua, now);
    final active = view.groups
        .where((g) => g.kind != TaskGroupKind.selesai)
        .fold(0, (sum, g) => sum + g.rows.length);
    final today = view.groups
        .where((g) => g.kind == TaskGroupKind.hariIni)
        .fold(0, (sum, g) => sum + g.rows.length);

    final wallets = ref.watch(walletsProvider).value ?? const [];
    final total = wallets.fold(0, (sum, w) => sum + w.balance);
    final week =
        ref.watch(weekSummaryProvider).value ?? (income: 0, expense: 0);
    final net = week.income - week.expense;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.s12,
      children: [
        Expanded(
          child: AppStatCard(
            label: 'Tugas aktif',
            value: '$active',
            caption: '$today jatuh tempo hari ini',
          ),
        ),
        Expanded(
          child: AppStatCard(
            label: 'Saldo',
            value: AppMoneyFormat.compact(total),
            caption:
                '${net == 0 ? AppMoneyFormat.compact(0) : AppMoneyFormat.signedCompact(net, income: net > 0)} '
                'minggu ini',
          ),
        ),
      ],
    );
  }
}
