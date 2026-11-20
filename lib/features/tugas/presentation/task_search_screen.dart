import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/routes.dart';
import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/features/tugas/application/task_list_providers.dart';
import 'package:super_app/features/tugas/application/task_list_view.dart';
import 'package:super_app/features/tugas/data/task_repository_provider.dart';

/// `/tugas/cari`: H04 Pencarian (Figma 56:2409) versi MVP: hanya tugas.
/// Chip filter dan hasil Catatan, Kuliah, Belajar (modul Tahap 2–3)
/// disembunyikan (F-57).
class TaskSearchScreen extends ConsumerStatefulWidget {
  const TaskSearchScreen({super.key});

  @override
  ConsumerState<TaskSearchScreen> createState() => _TaskSearchScreenState();
}

class _TaskSearchScreenState extends ConsumerState<TaskSearchScreen> {
  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _backSize = 40;
  static const double _iconSize = 20;
  static const double _borderWidth = 1;

  final TextEditingController _query = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(taskListItemsProvider).value ?? const [];
    final now = ref.watch(clockProvider)();
    final query = _query.text.trim();
    final rows = searchTaskRows(items, query, now);

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s12,
                AppSpace.s8,
                AppSpace.s20,
                AppSpace.s8,
              ),
              child: Row(
                spacing: AppSpace.s8,
                children: [
                  SizedBox.square(
                    dimension: _backSize,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: 'Kembali',
                      onPressed: context.pop,
                      icon: const AppIcon(AppIcons.arrowLeft),
                    ),
                  ),
                  Expanded(child: _field()),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.s20,
                  AppSpace.s8,
                  AppSpace.s20,
                  AppSpace.s20,
                ),
                children: [
                  if (query.isNotEmpty)
                    AppLabelText(
                      '${rows.length} hasil untuk “$query”',
                      style: AppText.labelSmall.copyWith(color: AppColors.gray),
                    ),
                  if (rows.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.s20),
                    AppLabelText(
                      'Tugas · ${rows.length}',
                      style: AppText.labelMedium.copyWith(
                        color: AppColors.lightGray,
                      ),
                    ),
                    for (final row in rows) ...[
                      const SizedBox(height: AppSpace.s12),
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
                        onDoneChanged: (done) => ref
                            .read(taskRepositoryProvider)
                            .setDone(row.id, done: done),
                        onTap: () =>
                            context.push(AppRoutes.tugasDetail(row.id)),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Search Field (56:2427): garis oranye saat fokus, ikon Search, dan
  /// ikon Close untuk mengosongkan kueri.
  Widget _field() {
    final hasText = _query.text.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s16,
        AppSpace.s12,
        AppSpace.s12,
        AppSpace.s12,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(
          color: _focus.hasFocus
              ? AppColors.brandingOrange
              : AppColors.darkGray,
          width: _borderWidth,
        ),
      ),
      child: Row(
        spacing: AppSpace.s12,
        children: [
          const AppIcon(
            AppIcons.search,
            color: AppColors.gray,
            size: _iconSize,
          ),
          Expanded(
            child: Material(
              type: MaterialType.transparency,
              child: TextField(
                controller: _query,
                focusNode: _focus,
                autofocus: true,
                textInputAction: TextInputAction.search,
                style: AppText.bodyLarge.copyWith(color: AppColors.white),
                cursorColor: AppColors.brandingOrange,
                // Placeholder belum ada di Figma (F-57).
                decoration: InputDecoration.collapsed(
                  hintText: 'Cari tugas',
                  hintStyle: AppText.bodyLarge.copyWith(color: AppColors.gray),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          if (hasText)
            Semantics(
              button: true,
              label: 'Hapus pencarian',
              child: GestureDetector(
                onTap: () => setState(_query.clear),
                child: const AppIcon(
                  AppIcons.close,
                  color: AppColors.gray,
                  size: _iconSize,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
