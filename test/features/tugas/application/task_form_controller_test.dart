import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/db/database_provider.dart';
import 'package:super_app/core/db/enums.dart';
import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/features/tugas/application/task_form_controller.dart';

import '../../../helpers/test_database.dart';

final _now = DateTime(2026, 11, 6, 10, 2);

void main() {
  late AppDatabase database;
  late ProviderContainer container;

  setUp(() {
    database = testDatabase();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        clockProvider.overrideWithValue(() => _now),
      ],
    );
    // Provider autoDispose: tetap hidup selama tes mendengarkan.
    container.listen(taskFormProvider, (_, _) {});
  });

  tearDown(() async {
    container.dispose();
    await database.close();
  });

  TaskFormController form() => container.read(taskFormProvider.notifier);
  TaskFormState state() => container.read(taskFormProvider);

  test('isian awal: hari ini 23.59, Sedang, tanpa mata kuliah', () {
    expect(state().dueAt, DateTime(2026, 11, 6, 23, 59));
    expect(state().priority, TaskPriority.medium);
    expect(state().courseId, isNull);
    expect(state().subtasks, isEmpty);
    expect(state().showTitleError, isFalse);
  });

  test('judul kosong atau spasi: tidak disimpan, pesan G2 muncul', () async {
    form()
      ..setTitle('   ')
      ..setCourse('c1', 'Pemrograman Mobile')
      ..setNotes('catatan');

    expect(await form().save(), isNull);
    expect(state().showTitleError, isTrue);
    expect(state().courseName, 'Pemrograman Mobile');
    expect(state().notes, 'catatan');
    expect(await database.select(database.tasks).get(), isEmpty);

    form().setTitle('L');
    expect(state().showTitleError, isFalse);
  });

  test('simpan: judul dirapikan, catatan kosong jadi null', () async {
    form()
      ..setTitle('  Kuis bab 5 ')
      ..setNotes('  ')
      ..setDueDate(DateTime(2026, 11, 9, 15, 30))
      ..setDueTime(12, 0)
      ..setPriority(TaskPriority.low)
      ..addSubtask('Baca bab 5')
      ..addSubtask('   ');

    final id = await form().save();
    expect(id, isNotNull);

    final task = await database.select(database.tasks).getSingle();
    expect(task.title, 'Kuis bab 5');
    expect(task.notes, isNull);
    expect(task.dueAt, DateTime(2026, 11, 9, 12));
    expect(task.priority, TaskPriority.low);
    final subtasks = await database.select(database.subtasks).get();
    expect(subtasks.map((s) => s.title), ['Baca bab 5']);
  });

  test('tanpa tanggal = deadline kosong', () {
    form().setDueDate(null);
    expect(state().dueDate, isNull);
    expect(state().dueAt, isNull);
  });

  test('ubah sub-tugas; dikosongkan = dihapus', () {
    form()
      ..addSubtask('A')
      ..addSubtask('B')
      ..renameSubtask(0, ' A2 ')
      ..renameSubtask(1, '');
    expect(state().subtasks, ['A2']);
  });
}
