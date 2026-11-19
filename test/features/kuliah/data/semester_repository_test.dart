import 'package:flutter_test/flutter_test.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/features/kuliah/data/semester_repository.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late SemesterRepository repository;
  var counter = 0;

  setUp(() {
    db = testDatabase();
    counter = 0;
    repository = SemesterRepository(
      db,
      userId: 'user-a',
      now: () => DateTime(2026, 11, 6),
      newId: () => 'sem-${counter++}',
    );
  });

  tearDown(() => db.close());

  Future<List<SyncQueueEntry>> queue() => db.select(db.syncQueue).get();

  test('belum ada semester: aktif null', () async {
    expect(await repository.getActiveSemester(), isNull);
    expect(await repository.getSemesters(), isEmpty);
  });

  test('tambah semester aktif tercatat di antrean', () async {
    final id = await repository.addSemester(
      name: 'Semester 7',
      startsOn: DateTime(2026, 9),
      endsOn: DateTime(2027, 1, 31),
      active: true,
    );
    final active = await repository.getActiveSemester();
    expect(active!.id, id);
    expect(active.name, 'Semester 7');
    // Insert + update (jadi aktif).
    expect((await queue()).map((q) => q.targetTable), [
      'semesters',
      'semesters',
    ]);
  });

  test('hanya satu semester aktif', () async {
    final s7 = await repository.addSemester(
      name: 'Semester 7',
      startsOn: DateTime(2026, 9),
      active: true,
    );
    final s8 = await repository.addSemester(
      name: 'Semester 8',
      startsOn: DateTime(2027, 2),
    );

    await repository.setActiveSemester(s8);

    final all = await repository.getSemesters();
    expect(all.map((s) => (s.id, s.isActive)), [(s8, true), (s7, false)]);
    expect((await repository.getActiveSemester())!.id, s8);
  });

  test('semester akun lain atau tidak ada = error', () async {
    await expectLater(
      repository.setActiveSemester('tidak-ada'),
      throwsStateError,
    );
    final other = SemesterRepository(db, userId: 'user-b');
    final id = await other.addSemester(name: 'Milik B', active: true);
    await expectLater(repository.setActiveSemester(id), throwsStateError);
    expect(await repository.getActiveSemester(), isNull);
  });
}
