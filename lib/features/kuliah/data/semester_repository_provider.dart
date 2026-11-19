import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:super_app/core/db/database_provider.dart';
import 'package:super_app/features/auth/application/current_user_id_provider.dart';
import 'package:super_app/features/kuliah/data/semester_repository.dart';

/// Repository semester untuk akun yang sedang login.
final semesterRepositoryProvider = Provider<SemesterRepository>((ref) {
  return SemesterRepository(
    ref.watch(appDatabaseProvider),
    userId: ref.watch(currentUserIdProvider),
  );
});
