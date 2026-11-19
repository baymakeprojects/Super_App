import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/routes.dart';
import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/features/tugas/application/task_list_providers.dart';
import 'package:super_app/features/tugas/application/task_list_view.dart';
import 'package:super_app/features/tugas/application/task_snackbar.dart';
import 'package:super_app/features/tugas/data/task_repository_provider.dart';

/// Layar 03 Tugas (Figma 14:127), dengan keadaan kosong E2 (67:1978) dan
/// snackbar Urungkan E4 (67:2114).
class TugasScreen extends ConsumerWidget {
  const TugasScreen({super.key});

  /// Ruang kosong di bawah daftar supaya baris terakhir tidak tertutup FAB:
  /// jarak FAB ke Bottom Nav (20) + tinggi FAB.
  static const double _fabClearance = AppSpace.s20 + AppFab.size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(taskListViewProvider).value;
    final snack = ref.watch(taskSnackbarProvider);

    return ColoredBox(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // E7 Memuat (F-56).
            if (view == null) const Positioned.fill(child: AppSkeletonPage()),
            if (view != null)
              Positioned.fill(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.s20,
                    AppSpace.s12,
                    AppSpace.s20,
                    AppSpace.s24 + _fabClearance,
                  ),
                  children: [
                    _Header(label: view.headerLabel),
                    const SizedBox(height: AppSpace.s20),
                    const _FilterChips(),
                    if (view.hasAnyTask)
                      for (final group in view.groups) ...[
                        const SizedBox(height: AppSpace.s20),
                        _Group(group: group),
                      ]
                    else ...[
                      const SizedBox(height: AppSpace.s20),
                      const _EmptySpacer(),
                      const SizedBox(height: AppSpace.s20),
                      AppEmptyState(
                        icon: AppIcons.task,
                        title: 'Belum ada tugas',
                        // Kalimat widget layar utama disembunyikan karena
                        // widget bukan MVP (keputusan Bayu, F-24).
                        message: 'Tambah tugas pertamamu.',
                        actionLabel: '+ Tambah tugas',
                        onAction: () => context.push(AppRoutes.tugasBaru),
                      ),
                    ],
                  ],
                ),
              ),
            Positioned(
              left: AppSpace.s20,
              right: AppSpace.s20,
              // E4: snackbar 12 di atas Bottom Nav, FAB 16 di atas snackbar.
              // Tanpa snackbar: FAB 20 di atas Bottom Nav.
              bottom: snack == null ? AppSpace.s20 : AppSpace.s12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpace.s16,
                children: [
                  AppFab(
                    semanticLabel: 'Tugas baru',
                    onPressed: () => context.push(AppRoutes.tugasBaru),
                  ),
                  if (snack != null)
                    SizedBox(
                      width: double.infinity,
                      child: AppSnackbar(
                        message: snack.message,
                        icon: snack.icon,
                        iconColor: snack.iconColor,
                        actionLabel: 'Urungkan',
                        onAction: ref.read(taskSnackbarProvider.notifier).undo,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.s4,
            children: [
              AppLabelText(
                label,
                style: AppText.labelSmall.copyWith(color: AppColors.gray),
              ),
              Text(
                'Tugas',
                style: AppText.headingLarge.copyWith(color: AppColors.white),
              ),
            ],
          ),
        ),
        AppCircleButton(
          icon: AppIcons.search,
          semanticLabel: 'Cari tugas',
          onPressed: () => context.push(AppRoutes.tugasCari),
        ),
      ],
    );
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(taskFilterProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: AppSpace.s8,
        children: [
          for (final filter in TaskFilter.values)
            AppChip(
              label: filter.label,
              selected: filter == selected,
              onTap: () => ref.read(taskFilterProvider.notifier).select(filter),
            ),
        ],
      ),
    );
  }
}

class _Group extends ConsumerWidget {
  const _Group({required this.group});

  final TaskGroupView group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.s8,
      children: [
        AppLabelText(
          group.label,
          style: AppText.labelSmall.copyWith(color: AppColors.gray),
        ),
        for (final row in group.rows)
          AppTaskItem(
            key: ValueKey(row.id),
            title: row.title,
            meta: row.meta,
            done: row.done,
            badge: row.badgeLabel == null
                ? null
                : AppBadge(label: row.badgeLabel!, type: row.badgeType),
            onDoneChanged: (done) {
              if (done) {
                ref
                    .read(taskSnackbarProvider.notifier)
                    .markDone(row.id, row.title);
              } else {
                ref.read(taskRepositoryProvider).setDone(row.id, done: false);
              }
            },
            onTap: () => context.push(AppRoutes.tugasDetail(row.id)),
          ),
      ],
    );
  }
}

/// Jarak kosong di atas keadaan kosong E2 (frame "Jarak", 64).
class _EmptySpacer extends StatelessWidget {
  const _EmptySpacer();

  static const double _height = 64;

  @override
  Widget build(BuildContext context) => const SizedBox(height: _height);
}
