import 'package:flutter_test/flutter_test.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/db/enums.dart';
import 'package:super_app/core/ui/app_badge.dart';
import 'package:super_app/features/tugas/application/task_list_view.dart';
import 'package:super_app/features/tugas/data/task_repository.dart';

/// "Sekarang" di semua tes: Jumat 6 Nov 2026 07.40, seperti frame Figma 03.
final _now = DateTime(2026, 11, 6, 7, 40);

TaskListItem _item(
  String title, {
  DateTime? dueAt,
  String? course,
  bool done = false,
  DateTime? completedAt,
}) {
  return TaskListItem(
    task: Task(
      id: title,
      userId: 'user-a',
      title: title,
      dueAt: dueAt,
      status: done ? TaskStatus.done : TaskStatus.active,
      completedAt: completedAt,
      createdAt: _now,
      updatedAt: _now,
    ),
    courseName: course,
  );
}

/// Contoh data frame 03.
final _figmaItems = [
  _item(
    'Revisi proposal penelitian',
    course: 'Metodologi Penelitian',
    dueAt: DateTime(2026, 11, 5, 23, 59),
  ),
  _item(
    'Laporan praktikum modul 5',
    course: 'Pemrograman Mobile',
    dueAt: DateTime(2026, 11, 6, 23, 59),
  ),
  _item(
    'Kuis bab 4',
    course: 'Kecerdasan Buatan',
    dueAt: DateTime(2026, 11, 7, 13),
  ),
  _item(
    'Presentasi kelompok',
    course: 'Manajemen Proyek TI',
    dueAt: DateTime(2026, 11, 9, 10),
  ),
  _item(
    'Baca jurnal referensi',
    course: 'Skripsi',
    dueAt: DateTime(2026, 11, 6, 7),
    done: true,
    completedAt: DateTime(2026, 11, 6, 7, 10),
  ),
];

void main() {
  test('contoh frame 03: kelompok, meta, badge, label', () {
    final view = buildTaskListView(_figmaItems, TaskFilter.semua, _now);

    expect(view.headerLabel, '4 aktif · 2 hari ini');
    expect(view.groups.map((g) => g.label), [
      'Hari ini · Jumat 6 Nov',
      'Besok',
      'Minggu ini',
      'Selesai',
    ]);

    final rows = [for (final g in view.groups) ...g.rows];
    expect(rows.map((r) => (r.meta, r.badgeLabel, r.badgeType)), [
      ('Metodologi Penelitian · kemarin', 'Terlambat', AppBadgeType.danger),
      ('Pemrograman Mobile · 23.59', 'Hari ini', AppBadgeType.warning),
      ('Kecerdasan Buatan · 13.00', 'Besok', AppBadgeType.neutral),
      ('Manajemen Proyek TI · Sen 10.00', '3 hari', AppBadgeType.neutral),
      ('Skripsi · 07.00', 'Selesai', AppBadgeType.success),
    ]);
  });

  test('tugas lewat jam hari ini = Terlambat, tetap di Hari ini', () {
    final view = buildTaskListView(
      [_item('Pagi', dueAt: DateTime(2026, 11, 6, 7))],
      TaskFilter.semua,
      _now,
    );
    final row = view.groups.single.rows.single;
    expect(view.groups.single.kind, TaskGroupKind.hariIni);
    expect((row.meta, row.badgeLabel), ('07.00', 'Terlambat'));
  });

  test('terlambat lebih dari sehari: "n hari lalu"', () {
    final view = buildTaskListView(
      [_item('Lama', dueAt: DateTime(2026, 11, 2, 10))],
      TaskFilter.semua,
      _now,
    );
    expect(view.groups.single.rows.single.meta, '4 hari lalu');
  });

  test('lebih dari 7 hari atau tanpa deadline masuk Nanti', () {
    final view = buildTaskListView(
      [
        _item('Jauh', dueAt: DateTime(2026, 11, 20, 9)),
        _item('Tanpa deadline', course: 'Skripsi'),
        _item('Tujuh hari', dueAt: DateTime(2026, 11, 13, 9)),
      ],
      TaskFilter.semua,
      _now,
    );
    expect(view.groups.map((g) => g.kind), [
      TaskGroupKind.mingguIni,
      TaskGroupKind.nanti,
    ]);
    final nanti = view.groups.last.rows;
    expect(nanti.map((r) => (r.meta, r.badgeLabel)), [
      ('09.00', '20 Nov'),
      ('Skripsi', null),
    ]);
    expect(view.groups.first.rows.single.badgeLabel, '7 hari');
  });

  test('filter Hari ini, Minggu ini, Selesai', () {
    List<TaskGroupKind> kinds(TaskFilter filter) => buildTaskListView(
      [..._figmaItems, _item('Jauh', dueAt: DateTime(2026, 11, 30))],
      filter,
      _now,
    ).groups.map((g) => g.kind).toList();

    expect(kinds(TaskFilter.hariIni), [TaskGroupKind.hariIni]);
    expect(kinds(TaskFilter.mingguIni), [
      TaskGroupKind.hariIni,
      TaskGroupKind.besok,
      TaskGroupKind.mingguIni,
    ]);
    expect(kinds(TaskFilter.selesai), [TaskGroupKind.selesai]);
  });

  test('Semua hanya menampilkan tugas selesai 7 hari terakhir', () {
    final items = [
      _item('Baru', done: true, completedAt: DateTime(2026, 11, 5)),
      _item('Lama', done: true, completedAt: DateTime(2026, 10, 20)),
    ];

    final semua = buildTaskListView(items, TaskFilter.semua, _now);
    expect(semua.groups.single.rows.map((r) => r.title), ['Baru']);

    final selesai = buildTaskListView(items, TaskFilter.selesai, _now);
    expect(selesai.groups.single.rows.map((r) => r.title), ['Baru', 'Lama']);
  });

  test('belum ada tugas sama sekali = keadaan kosong E2', () {
    final view = buildTaskListView(const [], TaskFilter.semua, _now);
    expect(view.hasAnyTask, isFalse);
    expect(view.headerLabel, 'Belum ada tugas');
    expect(view.groups, isEmpty);
  });

  test('filter tanpa hasil: daftar kosong tapi bukan keadaan E2', () {
    final view = buildTaskListView(
      [_item('Besok', dueAt: DateTime(2026, 11, 7, 9))],
      TaskFilter.hariIni,
      _now,
    );
    expect(view.hasAnyTask, isTrue);
    expect(view.groups, isEmpty);
    expect(view.headerLabel, '1 aktif · 0 hari ini');
  });
}
