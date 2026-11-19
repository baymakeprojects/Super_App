import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/features/kuliah/data/course_repository_provider.dart';
import 'package:super_app/features/kuliah/data/semester_repository_provider.dart';
import 'package:super_app/features/tugas/application/task_list_view.dart';
import 'package:super_app/features/tugas/data/task_repository_provider.dart';

/// Mata kuliah di layar 20. `null` = tidak ada atau sudah dihapus.
final courseDetailProvider = StreamProvider.autoDispose.family<Course?, String>(
  (ref, id) => ref.watch(courseRepositoryProvider).watchCourse(id),
);

/// Jadwal mingguan mata kuliah di layar 20.
final courseSessionsProvider = StreamProvider.autoDispose
    .family<List<ClassSession>, String>(
      (ref, id) => ref.watch(courseRepositoryProvider).watchSessions(id),
    );

/// Semester mata kuliah, untuk label "3 SKS · Semester 7".
final courseSemesterProvider = StreamProvider.autoDispose
    .family<Semester?, String>(
      (ref, semesterId) =>
          ref.watch(semesterRepositoryProvider).watchSemester(semesterId),
    );

/// Baris "Tugas aktif" di layar 20, dengan meta dan badge yang sama seperti
/// layar 03 (aturan `buildTaskListView`).
final courseTaskRowsProvider = StreamProvider.autoDispose
    .family<List<TaskRowView>, String>((ref, courseId) {
      final now = ref.watch(clockProvider)();
      return ref
          .watch(taskRepositoryProvider)
          .watchActiveTasksForCourse(courseId)
          .map(
            (items) => [
              for (final group in buildTaskListView(
                items,
                TaskFilter.semua,
                now,
              ).groups)
                ...group.rows,
            ],
          );
    });
