import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:super_app/core/db/database_provider.dart';
import 'package:super_app/features/auth/application/current_user_id_provider.dart';
import 'package:super_app/features/kuliah/data/course_repository.dart';

/// Repository mata kuliah untuk akun yang sedang login.
final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  return CourseRepository(
    ref.watch(appDatabaseProvider),
    userId: ref.watch(currentUserIdProvider),
  );
});
