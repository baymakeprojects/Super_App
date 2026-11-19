import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/routes.dart';
import 'package:super_app/core/db/enums.dart';
import 'package:super_app/core/sheets/date_sheet.dart';
import 'package:super_app/core/sheets/time_sheet.dart';
import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/core/utils/date_format.dart';
import 'package:super_app/features/kuliah/data/course_repository_provider.dart';
import 'package:super_app/features/tugas/application/task_form_controller.dart';
import 'package:super_app/features/tugas/presentation/course_sheet.dart';

/// Layar 15 Tugas baru (Figma 30:1381) dan H01 Edit tugas (54:2269), dengan
/// G2 isian belum lengkap (137:4349) dan pop-up P01 tanggal, P02 jam,
/// P03 mata kuliah.
///
/// Kartu "Ingatkan saya" di Figma adalah fitur Tahap 2, jadi
/// disembunyikan utuh (design-notes §7).
class TaskFormScreen extends ConsumerWidget {
  const TaskFormScreen({super.key, this.taskId});

  /// `null` = Tugas baru; id tugas = Edit tugas.
  final String? taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskId = this.taskId;
    if (taskId == null) return const _TaskForm(taskId: null);

    // H01: isian awal dibaca dari database dulu. Data lokal, jadi biasanya
    // hanya sekejap; sementara itu yang tampil hanya bar atas.
    final source = ref.watch(taskEditSourceProvider(taskId));
    if (source.value == null) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppTopAppBar(
          title: 'Edit tugas',
          leadingIcon: AppIcons.close,
          leadingSemanticLabel: 'Tutup',
          onLeadingPressed: () => context.pop(),
        ),
      );
    }
    return _TaskForm(taskId: taskId);
  }
}

class _TaskForm extends ConsumerStatefulWidget {
  const _TaskForm({required this.taskId});

  final String? taskId;

  @override
  ConsumerState<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends ConsumerState<_TaskForm> {
  late final _provider = taskFormProvider(widget.taskId);
  late final _titleController = TextEditingController(
    text: ref.read(_provider).title,
  );
  late final _notesController = TextEditingController(
    text: ref.read(_provider).notes,
  );

  bool get _isEdit => widget.taskId != null;

  TaskFormController get _form => ref.read(_provider.notifier);

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Tutup keyboard sebelum membuka pop-up.
  void _unfocus() => FocusScope.of(context).unfocus();

  Future<void> _pickCourse() async {
    _unfocus();
    final now = ref.read(clockProvider)();
    final options = await ref
        .read(courseRepositoryProvider)
        .loadCourseOptions(now: now);
    if (!mounted) return;

    final result = await showCourseSheet(
      context: context,
      options: options,
      selectedId: ref.read(_provider).courseId,
    );
    if (!mounted) return;
    switch (result) {
      case PickedCourse(:final course):
        _form.setCourse(course?.id, course?.name);
      case AddCourseRequested():
        // Mata kuliah baru dibuat di H02 Jadwal baru (keputusan Bayu,
        // W2-05, F-30).
        await context.push(AppRoutes.kuliahJadwalBaru);
    }
  }

  Future<void> _pickDate() async {
    _unfocus();
    final result = await showDateSheet(
      context: context,
      selected: ref.read(_provider).dueDate,
      today: ref.read(clockProvider)(),
      subtitle: 'Tenggat tugas',
    );
    if (result != null) _form.setDueDate(result.date);
  }

  Future<void> _pickTime(DateTime date) async {
    _unfocus();
    final form = ref.read(_provider);
    final result = await showTimeSheet(
      context: context,
      selected: (hour: form.dueHour, minute: form.dueMinute),
      subtitle: 'Jam deadline · ${AppDateFormat.weekdayShortDayMonth(date)}',
    );
    if (result != null) _form.setDueTime(result.hour, result.minute);
  }

  Future<void> _save() async {
    final id = await _form.save();
    if (id != null && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(_provider);
    final dueDate = form.dueDate;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppTopAppBar(
        title: _isEdit ? 'Edit tugas' : 'Tugas baru',
        leadingIcon: AppIcons.close,
        leadingSemanticLabel: 'Tutup',
        // Menutup tanpa konfirmasi (keputusan Bayu, W2-05).
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
            label: 'Judul tugas',
            placeholder: 'Contoh: laporan praktikum',
            controller: _titleController,
            // Tugas baru: langsung mengetik judul. Edit: keyboard tidak
            // langsung muncul (keputusan Bayu, W2-06, F-34).
            autofocus: !_isEdit,
            textInputAction: TextInputAction.next,
            errorText: form.showTitleError ? 'Judul wajib diisi' : null,
            onChanged: _form.setTitle,
          ),
          const SizedBox(height: AppSpace.s20),
          AppSelect(
            label: 'Mata kuliah',
            value: form.courseName ?? 'Tanpa mata kuliah',
            onTap: _pickCourse,
          ),
          const SizedBox(height: AppSpace.s20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.s12,
            children: [
              Expanded(
                child: AppSelect(
                  label: 'Tanggal',
                  value: dueDate == null
                      ? 'Tanpa tanggal'
                      : AppDateFormat.weekdayShortDayMonth(dueDate),
                  icon: AppIcons.calendar,
                  onTap: _pickDate,
                ),
              ),
              Expanded(
                // Tanpa tanggal: jam "—" dan tidak bisa dipilih (keputusan
                // Bayu, W2-05, F-28).
                child: AppSelect(
                  label: 'Jam',
                  value: dueDate == null
                      ? null
                      : AppDateFormat.time(form.dueAt ?? dueDate),
                  placeholder: '—',
                  icon: AppIcons.clock,
                  onTap: dueDate == null ? null : () => _pickTime(dueDate),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s20),
          _PriorityField(
            selected: form.priority,
            onSelected: _form.setPriority,
          ),
          const SizedBox(height: AppSpace.s20),
          _SubtaskField(
            subtasks: form.subtasks,
            onAdd: _form.addSubtask,
            onRename: _form.renameSubtask,
          ),
          const SizedBox(height: AppSpace.s20),
          AppInput(
            label: 'Catatan',
            placeholder: 'Tambahkan catatan (opsional)',
            controller: _notesController,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            onChanged: _form.setNotes,
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
              primaryLabel: 'Simpan tugas',
              onPrimaryPressed: form.saving ? null : _save,
            ),
    );
  }
}

/// Prioritas: chip Rendah, Sedang, Tinggi.
class _PriorityField extends StatelessWidget {
  const _PriorityField({required this.selected, required this.onSelected});

  static const List<(TaskPriority, String)> _options = [
    (TaskPriority.low, 'Rendah'),
    (TaskPriority.medium, 'Sedang'),
    (TaskPriority.high, 'Tinggi'),
  ];

  /// `null` = tugas lama tanpa prioritas: tidak ada chip terpilih.
  final TaskPriority? selected;
  final ValueChanged<TaskPriority> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.s8,
      children: [
        AppLabelText(
          'Prioritas',
          style: AppText.labelMedium.copyWith(color: AppColors.lightGray),
        ),
        Row(
          spacing: AppSpace.s8,
          children: [
            for (final (priority, label) in _options)
              AppChip(
                label: label,
                selected: priority == selected,
                onTap: () => onSelected(priority),
              ),
          ],
        ),
      ],
    );
  }
}

/// Sub-tugas: daftar Checklist Item + "+ Tambah sub-tugas".
///
/// Cara menambah dan mengubah belum didesain (keputusan Bayu, W2-05,
/// F-29): "+ Tambah sub-tugas" diganti kolom ketik; Enter menambah satu
/// baris dan kolom tetap terbuka. Mengetuk sub-tugas membuka teksnya untuk
/// diubah; dikosongkan = dihapus. Centang dilakukan di 16 Detail tugas.
class _SubtaskField extends StatefulWidget {
  const _SubtaskField({
    required this.subtasks,
    required this.onAdd,
    required this.onRename,
  });

  final List<FormSubtask> subtasks;
  final ValueChanged<String> onAdd;
  final void Function(int index, String title) onRename;

  @override
  State<_SubtaskField> createState() => _SubtaskFieldState();
}

class _SubtaskFieldState extends State<_SubtaskField> {
  /// Baris yang sedang diketik: indeks sub-tugas, atau [_adding] untuk
  /// sub-tugas baru. `null` = tidak ada.
  int? _editing;

  static const int _adding = -1;

  void _close() => setState(() => _editing = null);

  @override
  Widget build(BuildContext context) {
    final editing = _editing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.s4,
      children: [
        AppLabelText(
          'Sub-tugas',
          style: AppText.labelMedium.copyWith(color: AppColors.lightGray),
        ),
        for (var i = 0; i < widget.subtasks.length; i++)
          if (editing == i)
            _SubtaskInput(
              key: ValueKey('edit-$i'),
              initialText: widget.subtasks[i].title,
              onSubmitted: (text) {
                widget.onRename(i, text);
                _close();
              },
              onFocusLost: (text) {
                widget.onRename(i, text);
                _close();
              },
            )
          else
            Semantics(
              button: true,
              hint: 'Ketuk untuk mengubah',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _editing = i),
                // H01: centang tampil apa adanya, tapi diubah di 16 Detail
                // tugas (keputusan Bayu, W2-06).
                child: AppChecklistItem(
                  label: widget.subtasks[i].title,
                  done: widget.subtasks[i].done,
                  onChanged: null,
                ),
              ),
            ),
        if (editing == _adding)
          _SubtaskInput(
            key: const ValueKey('add'),
            initialText: '',
            keepOpenOnSubmit: true,
            onSubmitted: (text) {
              if (text.trim().isEmpty) {
                _close();
              } else {
                widget.onAdd(text);
              }
            },
            onFocusLost: (text) {
              widget.onAdd(text);
              _close();
            },
          )
        else
          Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _editing = _adding),
              child: AppLabelText(
                '+ Tambah sub-tugas',
                style: AppText.labelSmall.copyWith(color: AppColors.accentText),
              ),
            ),
          ),
      ],
    );
  }
}

/// Kolom ketik sub-tugas, berbentuk sama dengan Checklist Item (checkbox
/// kosong + teks Body/Medium) supaya baris tidak meloncat saat disimpan.
class _SubtaskInput extends StatefulWidget {
  const _SubtaskInput({
    super.key,
    required this.initialText,
    required this.onSubmitted,
    required this.onFocusLost,
    this.keepOpenOnSubmit = false,
  });

  final String initialText;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String> onFocusLost;

  /// Setelah Enter kolom dikosongkan dan tetap aktif (menambah beruntun).
  final bool keepOpenOnSubmit;

  @override
  State<_SubtaskInput> createState() => _SubtaskInputState();
}

class _SubtaskInputState extends State<_SubtaskInput> {
  late final _controller = TextEditingController(text: widget.initialText);
  final _focusNode = FocusNode();

  /// Sudah diserahkan ke induk; jangan diproses dua kali.
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus || _done) return;
    _done = true;
    widget.onFocusLost(_controller.text);
  }

  void _onSubmitted(String text) {
    if (_done) return;
    if (widget.keepOpenOnSubmit && text.trim().isNotEmpty) {
      widget.onSubmitted(text);
      _controller.clear();
      _focusNode.requestFocus();
      return;
    }
    _done = true;
    widget.onSubmitted(text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
      child: Row(
        spacing: AppSpace.s12,
        children: [
          const AppCheckbox(value: false, onChanged: null),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              textInputAction: TextInputAction.done,
              // Fokus tidak dilepas otomatis saat Enter; [_onSubmitted]
              // yang memutuskan.
              onEditingComplete: () {},
              onSubmitted: _onSubmitted,
              style: AppText.bodyMedium.copyWith(color: AppColors.white),
              cursorColor: AppColors.brandingOrange,
              decoration: InputDecoration.collapsed(
                hintText: 'Nama sub-tugas',
                hintStyle: AppText.bodyMedium.copyWith(color: AppColors.gray),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
