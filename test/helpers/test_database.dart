import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:super_app/core/db/app_database.dart';

/// Database di memori untuk tes.
///
/// `closeStreamsSynchronously: true` wajib di widget test: secara bawaan
/// drift menahan stream sebentar dengan timer setelah pendengar terakhir
/// pergi, dan timer itu tidak pernah berjalan di jam palsu widget test,
/// sehingga menutup database membuat tes menggantung.
AppDatabase testDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
}
