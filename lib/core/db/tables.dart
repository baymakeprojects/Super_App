import 'package:drift/drift.dart';

import 'package:super_app/core/db/enums.dart';

// Tabel lokal di HP. Kolomnya sama dengan migrasi Supabase W1-07
// (`supabase/migrations/*_mvp_tables.sql`): nama Dart camelCase, nama SQL
// snake_case. Relasi antartabel tidak dikunci di sini (Supabase yang
// menjaganya), supaya urutan data yang ditarik saat sinkron tidak masalah.

/// Kolom standar setiap tabel yang disinkron.
mixin SyncedColumns on Table {
  /// UUID v4, dibuat di HP.
  TextColumn get id => text()();
  TextColumn get userId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Terisi = sudah dihapus (soft delete).
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Profiles extends Table with SyncedColumns {
  TextColumn get name => text().nullable()();
  TextColumn get avatarUrl => text().nullable()();
}

class Semesters extends Table with SyncedColumns {
  TextColumn get name => text()();
  DateTimeColumn get startsOn => dateTime().nullable()();
  DateTimeColumn get endsOn => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
}

class Courses extends Table with SyncedColumns {
  TextColumn get semesterId => text()();
  TextColumn get name => text()();
  TextColumn get code => text().nullable()();
  IntColumn get credits => integer().nullable()();
  TextColumn get lecturer => text().nullable()();
  TextColumn get room => text().nullable()();
  TextColumn get color => text().nullable()();
}

class ClassSessions extends Table with SyncedColumns {
  TextColumn get courseId => text()();

  /// 1 = Senin … 7 = Minggu.
  IntColumn get weekday => integer()();

  /// Jam mulai, teks `HH:mm` (kolom `time` di Supabase).
  TextColumn get startsAt => text()();

  /// Jam selesai, teks `HH:mm`.
  TextColumn get endsAt => text()();
  TextColumn get room => text().nullable()();
}

class Tasks extends Table with SyncedColumns {
  /// Opsional: tugas tanpa mata kuliah.
  TextColumn get courseId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get dueAt => dateTime().nullable()();
  TextColumn get priority => textEnum<TaskPriority>().nullable()();
  TextColumn get status =>
      textEnum<TaskStatus>().withDefault(Constant(TaskStatus.active.name))();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

class Subtasks extends Table with SyncedColumns {
  TextColumn get taskId => text()();
  TextColumn get title => text()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer().withDefault(const Constant(0))();
}

class Wallets extends Table with SyncedColumns {
  TextColumn get name => text()();
  TextColumn get kind => textEnum<WalletKind>()();

  /// Rupiah. Saldo sekarang dihitung, tidak disimpan.
  IntColumn get openingBalance => integer().withDefault(const Constant(0))();
}

@DataClassName('Category')
class Categories extends Table with SyncedColumns {
  TextColumn get name => text()();
  TextColumn get kind => textEnum<MoneyKind>()();
  TextColumn get icon => text().nullable()();
}

/// Nama kelas datanya `MoneyTransaction` supaya tidak tertukar dengan
/// transaksi database.
@DataClassName('MoneyTransaction')
class Transactions extends Table with SyncedColumns {
  TextColumn get walletId => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get kind => textEnum<MoneyKind>()();

  /// Rupiah, selalu positif; arah uang dari [kind].
  IntColumn get amount => integer()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
}

/// Antrean perubahan yang belum dikirim ke Supabase. Hanya ada di HP.
@DataClassName('SyncQueueEntry')
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Nama tabel SQL yang berubah, misalnya `tasks`.
  TextColumn get targetTable => text().named('table_name')();

  /// Id baris yang berubah.
  TextColumn get rowId => text()();
  TextColumn get operation => textEnum<SyncOperation>()();
  DateTimeColumn get createdAt => dateTime()();
}
