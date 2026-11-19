import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/routes.dart';
import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/features/kuliah/application/kuliah_providers.dart';
import 'package:super_app/features/kuliah/application/kuliah_view.dart';

/// Layar 04 Kuliah (Figma 15:218) dengan keadaan kosong K1 (140:4698).
///
/// Ikon Materi dan bagian "Catatan terakhir" adalah fitur Tahap 2, jadi
/// disembunyikan utuh (design-notes §7).
class KuliahScreen extends ConsumerWidget {
  const KuliahScreen({super.key});

  static const EdgeInsets _padding = EdgeInsets.fromLTRB(
    AppSpace.s20,
    AppSpace.s12,
    AppSpace.s20,
    AppSpace.s24,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(kuliahViewProvider);

    return ColoredBox(
      color: AppColors.primary,
      child: SafeArea(
        bottom: false,
        child: view == null
            ? const SizedBox.expand()
            : view.isEmpty
            // K1: blok kosong di tengah sisa layar; di layar pendek ikut
            // digulir supaya tidak terpotong.
            ? Padding(
                padding: _padding.copyWith(bottom: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(label: view.headerLabel),
                    const SizedBox(height: AppSpace.s24),
                    _DayPicker(days: view.days),
                    const SizedBox(height: AppSpace.s24),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, box) => SingleChildScrollView(
                          padding: EdgeInsets.only(bottom: _padding.bottom),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: box.maxHeight - _padding.bottom,
                            ),
                            child: Center(
                              child: AppEmptyState(
                                icon: AppIcons.calendar,
                                title: 'Belum ada jadwal kuliah',
                                message:
                                    'Isi mata kuliah semester ini supaya pengingat '
                                    'kelas dan kalender bisa jalan.',
                                actionLabel: '+ Tambah jadwal',
                                onAction: () =>
                                    context.push(AppRoutes.kuliahJadwalBaru),
                                linkLabel: 'Atau isi lewat setup awal',
                                onLink: () =>
                                    context.push(AppRoutes.setupJadwal),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: _padding,
                children: [
                  _Header(label: view.headerLabel),
                  const SizedBox(height: AppSpace.s24),
                  _DayPicker(days: view.days),
                  const SizedBox(height: AppSpace.s24),
                  _DaySchedule(view: view),
                ],
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.label});

  /// `null` = belum ada semester aktif: baris label disembunyikan.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final label = this.label;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.s4,
            children: [
              if (label != null)
                AppLabelText(
                  label,
                  style: AppText.labelSmall.copyWith(color: AppColors.gray),
                ),
              Text(
                'Kuliah',
                style: AppText.headingLarge.copyWith(color: AppColors.white),
              ),
            ],
          ),
        ),
        AppCircleButton(
          icon: AppIcons.plus,
          semanticLabel: 'Jadwal baru',
          onPressed: () => context.push(AppRoutes.kuliahJadwalBaru),
        ),
      ],
    );
  }
}

class _DayPicker extends ConsumerWidget {
  const _DayPicker({required this.days});

  final List<DayPillView> days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      spacing: AppSpace.s8,
      children: [
        for (final day in days)
          Expanded(
            child: AppDayPill(
              day: day.dayLabel,
              date: day.dateLabel,
              selected: day.selected,
              onTap: () =>
                  ref.read(selectedDayProvider.notifier).select(day.date),
            ),
          ),
      ],
    );
  }
}

class _DaySchedule extends StatelessWidget {
  const _DaySchedule({required this.view});

  final KuliahView view;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.s12,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              view.dayTitle,
              style: AppText.headingSmall.copyWith(color: AppColors.white),
            ),
            AppLabelText(
              view.countLabel,
              style: AppText.labelSmall.copyWith(color: AppColors.gray),
            ),
          ],
        ),
        // Hari tanpa kelas: hanya judul hari dan "0 kelas" (F-37).
        for (final row in view.classes)
          AppClassItem(
            start: row.start,
            end: row.end,
            course: row.course,
            meta: row.meta,
            state: row.state,
            onTap: () => context.push(AppRoutes.kuliahDetail(row.courseId)),
          ),
      ],
    );
  }
}
