import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:super_app/core/db/database_provider.dart';
import 'package:super_app/features/auth/application/current_user_id_provider.dart';
import 'package:super_app/features/tugas/data/task_repository.dart';

/// Repository tugas untuk akun yang sedang login. Dibuat ulang otomatis
/// kalau akun berganti.
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(
    ref.watch(appDatabaseProvider),
    userId: ref.watch(currentUserIdProvider),
  );
});
