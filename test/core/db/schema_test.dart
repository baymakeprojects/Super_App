import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:super_app/core/db/app_database.dart';

/// Kolom setiap tabel menurut file migrasi Supabase.
Map<String, Set<String>> _supabaseColumns() {
  final tables = <String, Set<String>>{};
  final createTable = RegExp(
    r'create table public\.(\w+) \((.*?)\n\);',
    dotAll: true,
  );
  final column = RegExp(r'^  (\w+) ', multiLine: true);

  final migrations = Directory('supabase/migrations')
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.sql'));
  for (final file in migrations) {
    for (final match in createTable.allMatches(file.readAsStringSync())) {
      tables[match.group(1)!] = {
        for (final c in column.allMatches(match.group(2)!))
          if (c.group(1) != 'constraint') c.group(1)!,
      };
    }
  }
  return tables;
}

void main() {
  test('setiap tabel drift punya kolom yang sama dengan Supabase', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final supabase = _supabaseColumns();
    expect(supabase, isNotEmpty, reason: 'migrasi Supabase tidak terbaca');

    final local = {
      for (final table in database.allTables)
        table.actualTableName: {for (final c in table.$columns) c.name},
    };

    // sync_queue dan sync_cursors hanya ada di HP.
    expect(
      local.keys.toSet()..removeAll(['sync_queue', 'sync_cursors']),
      supabase.keys.toSet(),
    );
    for (final name in supabase.keys) {
      expect(local[name], supabase[name], reason: 'kolom tabel $name');
    }
  });
}
