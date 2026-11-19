import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/features/tugas/application/task_list_view.dart';
import 'package:super_app/features/tugas/data/task_repository.dart';
import 'package:super_app/features/tugas/data/task_repository_provider.dart';

/// Chip filter yang aktif di layar 03. Tetap tersimpan selama tab Tugas
/// hidup (pindah tab tidak mengulang filter).
final taskFilterProvider = NotifierProvider<TaskFilterNotifier, TaskFilter>(
  TaskFilterNotifier.new,
);

class TaskFilterNotifier extends Notifier<TaskFilter> {
  @override
  TaskFilter build() => TaskFilter.semua;

  void select(TaskFilter filter) => state = filter;
}

/// Semua tugas (beserta nama mata kuliah) dari database HP.
final taskListItemsProvider = StreamProvider<List<TaskListItem>>(
  (ref) => ref.watch(taskRepositoryProvider).watchTaskList(),
);

/// Isi layar 03 untuk filter yang aktif.
final taskListViewProvider = Provider<AsyncValue<TaskListView>>((ref) {
  final filter = ref.watch(taskFilterProvider);
  final now = ref.watch(clockProvider)();
  return ref
      .watch(taskListItemsProvider)
      .whenData((items) => buildTaskListView(items, filter, now));
});
