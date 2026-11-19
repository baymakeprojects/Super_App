import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/features/tugas/data/task_repository.dart';
import 'package:super_app/features/tugas/data/task_repository_provider.dart';

/// Tugas di layar 16 Detail tugas, ikut berubah saat diedit atau dicentang.
/// `null` = tidak ada atau sudah dihapus.
final taskDetailProvider = StreamProvider.autoDispose
    .family<TaskListItem?, String>(
      (ref, id) => ref.watch(taskRepositoryProvider).watchTaskItem(id),
    );

/// Sub-tugas di layar 16 Detail tugas.
final taskSubtasksProvider = StreamProvider.autoDispose
    .family<List<Subtask>, String>(
      (ref, id) => ref.watch(taskRepositoryProvider).watchSubtasks(id),
    );
