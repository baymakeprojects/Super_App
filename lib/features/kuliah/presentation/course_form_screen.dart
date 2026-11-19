import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/sheets/time_sheet.dart';
import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/features/kuliah/application/course_form_controller.dart';
import 'package:super_app/features/kuliah/application/semester_choices.dart';
import 'package:super_app/features/kuliah/data/course_repository.dart';
import 'package:super_app/features/kuliah/data/semester_repository_provider.dart';
import 'package:super_app/features/kuliah/presentation/semester_sheet.dart';

/// H02 Jadwal baru (Figma 54:2356), juga mode ubah di `/kuliah/:id/edit`,
/// dengan P20 Pilih semester (85:4227) saat belum ada semester aktif.
///
/// Baris "Ulangi tiap minggu" disembunyikan: di MVP jadwal selalu
/// mingguan dan pertemuan baru ada di Tahap 2 (keputusan Bayu, W2-09,
/// F-38).
class CourseFormScreen extends ConsumerWidget {
  const CourseFormScreen({super.key, this.courseId});

  /// `null` = Jadwal baru; id mata kuliah = Ubah jadwal.
  final String? courseId;

  static const String newTitle = 'Jadwal baru';
  static const String editTitle = 'Ubah jadwal';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseId = this.courseId;
    if (courseId == null) return const _CourseForm(courseId: null);

    final source = ref.watch(courseEditSourceProvider(courseId));
    if (source.value == null) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppTopAppBar(
          title: editTitle,
          leadingIcon: AppIcons.close,
          leadingSemanticLabel: 'Tutup',
          onLeadingPressed: () => context.pop(),
        ),
      );
    }
    return _CourseForm(courseId: courseId);
  }
}

class _CourseForm extends ConsumerStatefulWidget {
  const _CourseForm({required this.courseId});

  final String? courseId;

  @override
  ConsumerState<_CourseForm> createState() => _CourseFormState();
}

class _CourseFormState extends ConsumerState<_CourseForm> {
  /// Pilihan SKS, disalin dari Figma.
  static const List<int> _creditOptions = [2, 3, 4];

  /// Hari kuliah Senin–Sabtu, seperti Figma.
  static const int _days = 6;

  late final _provider = courseFormProvider(widget.courseId);
  late final _name = TextEditingController(text: ref.read(_provider).name);
  late final _lecturer = TextEditingController(
    text: ref.read(_provider).lecturer,
  );
  late final _room = TextEditingController(text: ref.read(_provider).room);

  bool get _isEdit => widget.courseId != null;

  CourseFormController get _form => ref.read(_provider.notifier);

  @override
  void dispose() {
    _name.dispose();
    _lecturer.dispose();
    _room.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool start}) async {
    FocusScope.of(context).unfocus();
    final form = ref.read(_provider);
    final minutes = start ? form.startMinutes : form.endMinutes;
    final day = CourseRepository.weekdayName(form.weekday);
    final result = await showTimeSheet(
      context: context,
      selected: (
        hour: minutes ~/ Duration.minutesPerHour,
        minute: minutes % Duration.minutesPerHour,
      ),
      // P02 dipakai ulang; keterangannya mengikuti pola "Jam deadline ·
      // Jum, 6 Nov" (F-38).
      subtitle: '${start ? 'Jam mulai' : 'Jam selesai'} · $day',
    );
    if (result == null) return;
    final picked = result.hour * Duration.minutesPerHour + result.minute;
    if (start) {
      _form.setStart(picked);
    } else {
      _form.setEnd(picked);
    }
  }

  Future<void> _save() async {
    if (!_form.validate()) return;

    String? semesterId;
    if (!_isEdit) {
      final semesters = ref.read(semesterRepositoryProvider);
      semesterId = (await semesters.getActiveSemester())?.id;
      if (semesterId == null) {
        // Belum ada semester aktif: pilih dulu lewat P20 (navigasi.md).
        final today = ref.read(clockProvider)();
        final choices = await loadSemesterChoices(semesters, today: today);
        if (!mounted) return;
        final choice = await showSemesterSheet(
          context: context,
          choices: choices,
        );
        if (choice == null) return;
        semesterId = await activateSemesterChoice(semesters, choice);
      }
    }

    final id = await _form.save(semesterId: semesterId);
    if (id != null && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(_provider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppTopAppBar(
        title: _isEdit ? CourseFormScreen.editTitle : CourseFormScreen.newTitle,
        leadingIcon: AppIcons.close,
        leadingSemanticLabel: 'Tutup',
        onLeadingPressed: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s20,
          AppSpace.s8,
          AppSpace.s20,
          AppSpace.s24,
        ),
        children: [
          AppInput(
            label: 'Nama mata kuliah',
            controller: _name,
            autofocus: !_isEdit,
            textInputAction: TextInputAction.next,
            // Pola G2 (F-38).
            errorText: form.showNameError
                ? 'Nama mata kuliah wajib diisi'
                : null,
            onChanged: _form.setName,
          ),
          const SizedBox(height: AppSpace.s20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.s12,
            children: [
              Expanded(
                child: AppInput(
                  label: 'Dosen',
                  controller: _lecturer,
                  textInputAction: TextInputAction.next,
                  onChanged: _form.setLecturer,
                ),
              ),
              Expanded(
                child: AppInput(
                  label: 'Ruang',
                  controller: _room,
                  textInputAction: TextInputAction.done,
                  onChanged: _form.setRoom,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s20),
          _Field(
            label: 'SKS',
            child: Wrap(
              spacing: AppSpace.s8,
              runSpacing: AppSpace.s8,
              children: [
                for (final credits in _creditOptions)
                  AppChip(
                    label: '$credits SKS',
                    selected: form.credits == credits,
                    onTap: () => _form.setCredits(credits),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s20),
          _Field(
            label: 'Hari',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var weekday = 1; weekday <= _days; weekday++)
                  AppDayCell(
                    day: CourseRepository.weekdayName(weekday).substring(0, 3),
                    state: form.weekday == weekday
                        ? AppDayCellState.selected
                        : AppDayCellState.normal,
                    onTap: () => _form.setWeekday(weekday),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.s8,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpace.s12,
                children: [
                  Expanded(
                    child: AppSelect(
                      label: 'Mulai',
                      value: minutesToDisplay(form.startMinutes),
                      icon: AppIcons.clock,
                      onTap: () => _pickTime(start: true),
                    ),
                  ),
                  Expanded(
                    child: AppSelect(
                      label: 'Selesai',
                      value: minutesToDisplay(form.endMinutes),
                      icon: AppIcons.clock,
                      onTap: () => _pickTime(start: false),
                    ),
                  ),
                ],
              ),
              // Belum ada desain error untuk Select; gaya pesan sama dengan
              // Input Error (F-38).
              if (form.showTimeError)
                Text(
                  'Jam selesai harus setelah jam mulai',
                  style: AppText.bodySmall.copyWith(color: AppColors.danger),
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: _isEdit
          ? AppActionBar(
              secondaryLabel: 'Batal',
              onSecondaryPressed: () => context.pop(),
              primaryLabel: 'Simpan perubahan',
              onPrimaryPressed: form.saving ? null : _save,
            )
          : AppActionBar(
              primaryLabel: 'Simpan jadwal',
              onPrimaryPressed: form.saving ? null : _save,
            ),
    );
  }
}

/// Label kecil di atas sekelompok pilihan (SKS, Hari).
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.s8,
      children: [
        AppLabelText(
          label,
          style: AppText.labelMedium.copyWith(color: AppColors.lightGray),
        ),
        child,
      ],
    );
  }
}
