import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/db/enums.dart';
import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/core/utils/date_format.dart';
import 'package:super_app/features/tugas/data/task_repository.dart';
import 'package:super_app/features/tugas/data/task_repository_provider.dart';

/// Satu sub-tugas di form. [id] `null` = baru, belum tersimpan.
class FormSubtask {
  const FormSubtask({this.id, required this.title, this.done = false});

  final String? id;
  final String title;

  /// Hanya tampilan di H01; centang diubah di 16 Detail tugas.
  final bool done;

  FormSubtask withTitle(String title) =>
      FormSubtask(id: id, title: title, done: done);
}

/// Isian form 15 Tugas baru dan H01 Edit tugas.
class TaskFormState {
  const TaskFormState({
    required this.title,
    required this.courseId,
    required this.courseName,
    required this.dueDate,
    required this.dueHour,
    required this.dueMinute,
    required this.priority,
    required this.subtasks,
    required this.notes,
    required this.showTitleError,
    required this.saving,
  });

  final String title;

  /// `null` = "Tanpa mata kuliah".
  final String? courseId;
  final String? courseName;

  /// Tanggal deadline tanpa jam. `null` = "Tanpa tanggal".
  final DateTime? dueDate;
  final int dueHour;
  final int dueMinute;

  /// `null` hanya untuk tugas lama tanpa prioritas (tidak ada chip terpilih).
  final TaskPriority? priority;
  final List<FormSubtask> subtasks;
  final String notes;

  /// G2: tombol simpan diketuk saat judul kosong. Hilang saat mengetik.
  final bool showTitleError;

  final bool saving;

  /// Deadline lengkap (tanggal + jam), `null` kalau tanpa tanggal.
  DateTime? get dueAt {
    final date = dueDate;
    if (date == null) return null;
    return DateTime(date.year, date.month, date.day, dueHour, dueMinute);
  }

  TaskFormState copyWith({
    String? title,
    (String?, String?)? course,
    (DateTime?,)? dueDate,
    int? dueHour,
    int? dueMinute,
    TaskPriority? priority,
    List<FormSubtask>? subtasks,
    String? notes,
    bool? showTitleError,
    bool? saving,
  }) {
    return TaskFormState(
      title: title ?? this.title,
      courseId: course != null ? course.$1 : courseId,
      courseName: course != null ? course.$2 : courseName,
      dueDate: dueDate != null ? dueDate.$1 : this.dueDate,
      dueHour: dueHour ?? this.dueHour,
      dueMinute: dueMinute ?? this.dueMinute,
      priority: priority ?? this.priority,
      subtasks: subtasks ?? this.subtasks,
      notes: notes ?? this.notes,
      showTitleError: showTitleError ?? this.showTitleError,
      saving: saving ?? this.saving,
    );
  }
}

/// Data awal H01: tugas yang diubah dan sub-tugasnya.
class TaskEditSource {
  const TaskEditSource({required this.item, required this.subtasks});

  final TaskListItem item;
  final List<Subtask> subtasks;
}

/// Isian awal H01, dibaca sekali saat layar dibuka. `null` = tugas tidak
/// ada atau sudah dihapus.
final taskEditSourceProvider = FutureProvider.autoDispose
    .family<TaskEditSource?, String>((ref, id) async {
      final repository = ref.read(taskRepositoryProvider);
      final item = await repository.getTaskItem(id);
      if (item == null) return null;
      return TaskEditSource(
        item: item,
        subtasks: await repository.getSubtasks(id),
      );
    });

/// Form tugas. Argumen `null` = 15 Tugas baru; id tugas = H01 Edit tugas
/// (pastikan [taskEditSourceProvider] untuk id itu sudah selesai dibaca).
/// Dibuang otomatis saat layar ditutup, jadi setiap membuka form mulai dari
/// isian awal.
final taskFormProvider = NotifierProvider.autoDispose
    .family<TaskFormController, TaskFormState, String?>(TaskFormController.new);

class TaskFormController extends Notifier<TaskFormState> {
  TaskFormController(this.taskId);

  /// `null` = tugas baru.
  final String? taskId;

  /// Jam deadline bawaan: 23.59 (keputusan Bayu, W2-05).
  static const int defaultHour = 23;
  static const int defaultMinute = 59;

  @override
  TaskFormState build() {
    final taskId = this.taskId;
    if (taskId != null) {
      final source = ref.read(taskEditSourceProvider(taskId)).value;
      if (source != null) return _fromTask(source);
    }

    // Isian awal tugas baru (keputusan Bayu, W2-05): deadline hari ini
    // 23.59, prioritas Sedang, tanpa mata kuliah.
    final now = ref.read(clockProvider)();
    return TaskFormState(
      title: '',
      courseId: null,
      courseName: null,
      dueDate: AppDateFormat.dateOnly(now),
      dueHour: defaultHour,
      dueMinute: defaultMinute,
      priority: TaskPriority.medium,
      subtasks: const [],
      notes: '',
      showTitleError: false,
      saving: false,
    );
  }

  static TaskFormState _fromTask(TaskEditSource source) {
    final task = source.item.task;
    final due = task.dueAt?.toLocal();
    return TaskFormState(
      title: task.title,
      courseId: task.courseId,
      courseName: source.item.courseName,
      dueDate: due == null ? null : AppDateFormat.dateOnly(due),
      dueHour: due?.hour ?? defaultHour,
      dueMinute: due?.minute ?? defaultMinute,
      priority: task.priority,
      subtasks: [
        for (final s in source.subtasks)
          FormSubtask(id: s.id, title: s.title, done: s.isDone),
      ],
      notes: task.notes ?? '',
      showTitleError: false,
      saving: false,
    );
  }

  void setTitle(String title) {
    state = state.copyWith(title: title, showTitleError: false);
  }

  /// [id] `null` = "Tanpa mata kuliah".
  void setCourse(String? id, String? name) {
    state = state.copyWith(course: (id, name));
  }

  /// [date] `null` = "Tanpa tanggal".
  void setDueDate(DateTime? date) {
    state = state.copyWith(
      dueDate: (date == null ? null : AppDateFormat.dateOnly(date),),
    );
  }

  void setDueTime(int hour, int minute) {
    state = state.copyWith(dueHour: hour, dueMinute: minute);
  }

  void setPriority(TaskPriority priority) {
    state = state.copyWith(priority: priority);
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  /// Tambah sub-tugas di akhir. Teks kosong diabaikan.
  void addSubtask(String title) {
    final text = title.trim();
    if (text.isEmpty) return;
    state = state.copyWith(
      subtasks: [
        ...state.subtasks,
        FormSubtask(title: text),
      ],
    );
  }

  /// Ubah sub-tugas ke-[index]. Teks dikosongkan = sub-tugas dihapus.
  void renameSubtask(int index, String title) {
    final text = title.trim();
    final subtasks = [...state.subtasks];
    if (text.isEmpty) {
      subtasks.removeAt(index);
    } else {
      subtasks[index] = subtasks[index].withTitle(text);
    }
    state = state.copyWith(subtasks: subtasks);
  }

  /// Simpan tugas. Mengembalikan id tugas, atau `null` kalau judul kosong
  /// (G2: pesan muncul di kolom judul, isian lain tetap).
  Future<String?> save() async {
    if (state.saving) return null;
    final title = state.title.trim();
    if (title.isEmpty) {
      state = state.copyWith(showTitleError: true);
      return null;
    }

    state = state.copyWith(saving: true);
    try {
      final repository = ref.read(taskRepositoryProvider);
      final notes = state.notes.trim();
      final taskId = this.taskId;
      if (taskId == null) {
        return await repository.addTask(
          title: title,
          courseId: state.courseId,
          notes: notes.isEmpty ? null : notes,
          dueAt: state.dueAt,
          priority: state.priority,
          subtasks: [for (final s in state.subtasks) s.title],
        );
      }
      await repository.saveTaskEdit(
        taskId,
        title: title,
        courseId: state.courseId,
        notes: notes.isEmpty ? null : notes,
        dueAt: state.dueAt,
        priority: state.priority,
        subtasks: [for (final s in state.subtasks) (id: s.id, title: s.title)],
      );
      return taskId;
    } finally {
      if (ref.mounted) state = state.copyWith(saving: false);
    }
  }
}
