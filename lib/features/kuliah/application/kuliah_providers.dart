import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/features/kuliah/application/kuliah_view.dart';
import 'package:super_app/features/kuliah/data/course_repository.dart';
import 'package:super_app/features/kuliah/data/course_repository_provider.dart';
import 'package:super_app/features/kuliah/data/semester_repository_provider.dart';

/// Semester aktif, `null` kalau belum ada.
final activeSemesterProvider = StreamProvider<Semester?>(
  (ref) => ref.watch(semesterRepositoryProvider).watchActiveSemester(),
);

/// Semua kelas mingguan semester aktif.
final scheduleProvider = StreamProvider<List<ScheduleEntry>>((ref) {
  final semester = ref.watch(activeSemesterProvider).value;
  if (semester == null) return Stream.value(const []);
  return ref.watch(courseRepositoryProvider).watchSchedule(semester.id);
});

/// Hari yang dipilih lewat Day Pill. `null` = hari bawaan (hari ini).
final selectedDayProvider = NotifierProvider<SelectedDayNotifier, DateTime?>(
  SelectedDayNotifier.new,
);

class SelectedDayNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void select(DateTime day) => state = day;
}

/// Isi layar 04. `null` selama data belum siap.
final kuliahViewProvider = Provider<KuliahView?>((ref) {
  final semester = ref.watch(activeSemesterProvider);
  final schedule = ref.watch(scheduleProvider);
  if (!semester.hasValue || !schedule.hasValue) return null;

  final now = ref.watch(clockProvider)();
  return buildKuliahView(
    semester: semester.value,
    entries: schedule.value!,
    now: now,
    selectedDay: ref.watch(selectedDayProvider) ?? kuliahDefaultDay(now),
  );
});
