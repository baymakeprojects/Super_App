import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/routes.dart';
import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/db/enums.dart';
import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/core/utils/date_format.dart';
import 'package:super_app/features/tugas/application/task_detail_providers.dart';
import 'package:super_app/features/tugas/application/task_list_view.dart';
import 'package:super_app/features/tugas/application/task_snackbar.dart';
import 'package:super_app/features/tugas/data/task_repository.dart';
import 'package:super_app/features/tugas/data/task_repository_provider.dart';

/// Layar 16 Detail tugas (Figma 30:1472) dengan P05 Konfirmasi hapus
/// (50:611).
///
/// Baris pengingat dan bagian Lampiran adalah fitur Tahap 2, jadi
/// disembunyikan utuh (design-notes §7). Bagian tanpa data (deadline, mata
/// kuliah, sub-tugas, catatan) juga disembunyikan (keputusan Bayu, W2-06,
/// F-33).
class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(taskDetailProvider(taskId));
    final item = itemAsync.value;
    final subtasks = ref.watch(taskSubtasksProvider(taskId)).value ?? const [];
    final now = ref.watch(clockProvider)();

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppTopAppBar(
        title: 'Detail tugas',
        leadingIcon: AppIcons.arrowLeft,
        leadingSemanticLabel: 'Kembali',
        onLeadingPressed: () => context.pop(),
        trailingIcon: item == null ? null : AppIcons.edit,
        trailingSemanticLabel: 'Edit tugas',
        onTrailingPressed: () => context.push(AppRoutes.tugasEdit(taskId)),
      ),
      // Data lokal: biasanya langsung ada. Selama dimuat: E7 (F-56). Tugas
      // yang sudah dihapus: hanya bar atas.
      body: item == null
          ? (itemAsync.isLoading ? const AppSkeletonPage() : null)
          : _DetailBody(item: item, subtasks: subtasks, now: now),
      bottomNavigationBar: item == null
          ? null
          : _DetailActions(item: item, subtasks: subtasks),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.item,
    required this.subtasks,
    required this.now,
  });

  // Ukuran tetap dari Figma (bukan variabel Figma): ikon baris meta.
  static const double _metaIconSize = 18;

  static const Map<TaskPriority, String> _priorityLabels = {
    TaskPriority.low: 'Prioritas rendah',
    TaskPriority.medium: 'Prioritas sedang',
    TaskPriority.high: 'Prioritas tinggi',
  };

  final TaskListItem item;
  final List<Subtask> subtasks;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = item.task;
    final due = task.dueAt?.toLocal();
    final course = item.courseName;
    final notes = task.notes;
    final status = taskStatusBadge(task, now);
    final priority = task.priority;
    final doneCount = subtasks.where((s) => s.isDone).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s20,
        AppSpace.s8,
        AppSpace.s20,
        AppSpace.s24,
      ),
      children: [
        if (status != null || priority != null) ...[
          Row(
            spacing: AppSpace.s8,
            children: [
              if (status != null)
                AppBadge(label: status.label, type: status.type),
              if (priority != null) AppBadge(label: _priorityLabels[priority]!),
            ],
          ),
          const SizedBox(height: AppSpace.s20),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpace.s12,
          children: [
            Text(
              task.title,
              style: AppText.headingLarge.copyWith(color: AppColors.white),
            ),
            if (due != null)
              _MetaRow(
                icon: AppIcons.calendar,
                text:
                    '${AppDateFormat.weekdayCommaDayMonth(due)} · '
                    '${AppDateFormat.time(due)}',
              ),
            if (course != null) _MetaRow(icon: AppIcons.learn, text: course),
          ],
        ),
        if (subtasks.isNotEmpty) ...[
          const SizedBox(height: AppSpace.s20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.s8,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sub-tugas',
                    style: AppText.headingSmall.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  AppLabelText(
                    '$doneCount/${subtasks.length} selesai',
                    style: AppText.labelSmall.copyWith(color: AppColors.gray),
                  ),
                ],
              ),
              AppProgressBar(value: 100 * doneCount / subtasks.length),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final subtask in subtasks)
                    AppChecklistItem(
                      label: subtask.title,
                      done: subtask.isDone,
                      onChanged: (done) => ref
                          .read(taskRepositoryProvider)
                          .setSubtaskDone(subtask.id, done: done),
                    ),
                ],
              ),
            ],
          ),
        ],
        if (notes != null) ...[
          const SizedBox(height: AppSpace.s20),
          // Form hanya punya satu kolom Catatan, jadi kartu tanpa judul
          // dan isinya utuh (keputusan Bayu, W2-06, F-32).
          AppCard(eyebrow: '[Catatan]', body: notes, bodyMaxLines: null),
        ],
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final AppIcons icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: AppSpace.s8,
      children: [
        AppIcon(
          icon,
          size: _DetailBody._metaIconSize,
          color: AppColors.lightGray,
        ),
        Expanded(
          child: Text(
            text,
            style: AppText.bodyMedium.copyWith(color: AppColors.lightGray),
          ),
        ),
      ],
    );
  }
}

/// Action Bar: Hapus (P05) dan Tandai selesai.
class _DetailActions extends ConsumerWidget {
  const _DetailActions({required this.item, required this.subtasks});

  final TaskListItem item;
  final List<Subtask> subtasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = item.task;
    final done = task.status == TaskStatus.done;

    return AppActionBar(
      secondaryLabel: 'Hapus',
      onSecondaryPressed: () => _confirmDelete(context, ref),
      // Tugas yang sudah selesai: kembalikan jadi aktif, tetap di layar ini
      // (keputusan Bayu, W2-06, F-33).
      primaryLabel: done ? 'Tandai belum selesai' : 'Tandai selesai',
      onPrimaryPressed: done
          ? () => ref.read(taskRepositoryProvider).setDone(task.id, done: false)
          : () {
              // Kembali ke daftar dengan snackbar Urungkan, sama seperti
              // mencentang di 03 (keputusan Bayu, W2-06).
              final snackbar = ref.read(taskSnackbarProvider.notifier);
              context.pop();
              snackbar.markDone(task.id, task.title);
            },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppBottomSheet<bool>(
      context: context,
      builder: (_) => DeleteTaskSheet(
        title: item.task.title,
        subtaskCount: subtasks.length,
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Kembali ke daftar dulu, baru hapus + snackbar Urungkan E4
    // (navigasi.md › Aturan kembali).
    final snackbar = ref.read(taskSnackbarProvider.notifier);
    context.pop();
    await snackbar.delete(item.task.id, item.task.title);
  }
}

/// P05 Konfirmasi hapus: tanpa tombol tutup, Batal + Hapus tugas (Danger).
/// Mengembalikan `true` kalau Hapus tugas diketuk.
class DeleteTaskSheet extends StatelessWidget {
  const DeleteTaskSheet({
    super.key,
    required this.title,
    required this.subtaskCount,
  });

  final String title;
  final int subtaskCount;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    // Teks Figma menyebut "HP dan desktop" dan "tidak bisa dibatalkan",
    // padahal desktop baru Tahap 2 dan hapus masih bisa diurungkan
    // (keputusan Bayu, W2-06, F-35).
    final message = subtaskCount == 0
        ? '“$title” akan dihapus.'
        : '“$title” dan $subtaskCount sub-tugasnya akan dihapus.';

    return AppBottomSheet(
      title: 'Hapus tugas ini?',
      showClose: false,
      body: Text(
        message,
        style: AppText.bodyLarge.copyWith(color: AppColors.lightGray),
      ),
      footer: [
        AppButton(
          label: 'Batal',
          style: AppButtonStyle.ghost,
          onPressed: () => navigator.pop(false),
        ),
        AppButton(
          label: 'Hapus tugas',
          style: AppButtonStyle.danger,
          onPressed: () => navigator.pop(true),
        ),
      ],
    );
  }
}
