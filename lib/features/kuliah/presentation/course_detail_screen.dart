import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/routes.dart';
import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/features/kuliah/application/course_detail_providers.dart';
import 'package:super_app/features/kuliah/data/course_repository.dart';
import 'package:super_app/features/tugas/application/task_list_view.dart';
import 'package:super_app/features/tugas/data/task_repository_provider.dart';

/// Layar 20 Detail mata kuliah, versi MVP (Figma 158:15146): info mata
/// kuliah lalu "Tugas aktif · n" dengan Task Item. Kehadiran dan
/// Pertemuan menyusul di Tahap 2 (design-notes §7).
class CourseDetailScreen extends ConsumerWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(courseDetailProvider(courseId));
    final course = courseAsync.value;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppTopAppBar(
        title: 'Mata kuliah',
        leadingIcon: AppIcons.arrowLeft,
        leadingSemanticLabel: 'Kembali',
        onLeadingPressed: () => context.pop(),
        trailingIcon: course == null ? null : AppIcons.edit,
        trailingSemanticLabel: 'Ubah jadwal',
        onTrailingPressed: () => context.push(AppRoutes.kuliahEdit(courseId)),
      ),
      // Selama dimuat: E7 (F-56). Mata kuliah yang dihapus: hanya bar atas.
      body: course == null
          ? (courseAsync.isLoading ? const AppSkeletonPage() : null)
          : _DetailBody(course: course),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.course});

  // Ukuran tetap dari Figma (bukan variabel Figma): ikon baris info.
  static const double _metaIconSize = 18;

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions =
        ref.watch(courseSessionsProvider(course.id)).value ?? const [];
    final semester = ref.watch(courseSemesterProvider(course.semesterId)).value;
    final tasks = ref.watch(courseTaskRowsProvider(course.id)).value;
    final credits = course.credits;
    final lecturer = course.lecturer;
    final room = course.room;

    final label = [
      if (credits != null) '$credits SKS',
      ?semester?.name,
    ].join(' · ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s20,
        AppSpace.s8,
        AppSpace.s20,
        AppSpace.s24,
      ),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpace.s12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpace.s4,
              children: [
                if (label.isNotEmpty)
                  AppLabelText(
                    label,
                    style: AppText.labelSmall.copyWith(color: AppColors.gray),
                  ),
                Text(
                  course.name,
                  style: AppText.headingLarge.copyWith(color: AppColors.white),
                ),
              ],
            ),
            // Baris tanpa data disembunyikan (keputusan Bayu, W2-10, F-40).
            if (lecturer != null) _MetaRow(icon: AppIcons.user, text: lecturer),
            for (final session in sessions)
              _MetaRow(
                icon: AppIcons.clock,
                text:
                    '${CourseRepository.weekdayName(session.weekday)} · '
                    '${CourseRepository.displayTime(session.startsAt)}–'
                    '${CourseRepository.displayTime(session.endsAt)}',
              ),
            if (room != null) _MetaRow(icon: AppIcons.home, text: room),
          ],
        ),
        if (tasks != null) ...[
          const SizedBox(height: AppSpace.s20),
          _ActiveTasks(rows: tasks),
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

/// "Tugas aktif · n" dan Task Item. Tanpa tugas: hanya label "· 0" (F-40).
class _ActiveTasks extends ConsumerWidget {
  const _ActiveTasks({required this.rows});

  final List<TaskRowView> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.s8,
      children: [
        AppLabelText(
          'Tugas aktif · ${rows.length}',
          style: AppText.labelSmall.copyWith(color: AppColors.gray),
        ),
        for (final row in rows)
          AppTaskItem(
            key: ValueKey(row.id),
            title: row.title,
            meta: row.meta,
            done: false,
            badge: row.badgeLabel == null
                ? null
                : AppBadge(label: row.badgeLabel!, type: row.badgeType),
            // Snackbar Urungkan hanya ada di 03; di sini tugas langsung
            // selesai dan hilang dari daftar (keputusan Bayu, W2-10, F-40).
            onDoneChanged: (done) =>
                ref.read(taskRepositoryProvider).setDone(row.id, done: done),
            onTap: () => context.push(AppRoutes.tugasDetail(row.id)),
          ),
      ],
    );
  }
}
