import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/ui/app_class_item.dart';
import 'package:super_app/features/kuliah/application/kuliah_view.dart';
import 'package:super_app/features/kuliah/data/course_repository.dart';

/// "Sekarang" seperti frame 04: Jumat 6 Nov 2026 09.10.
final _now = DateTime(2026, 11, 6, 9, 10);

final _semester = Semester(
  id: 's7',
  userId: 'u',
  name: 'Semester 7',
  startsOn: DateTime(2026, 9),
  isActive: true,
  createdAt: _now,
  updatedAt: _now,
);

ScheduleEntry _entry(
  String name,
  int weekday,
  String start,
  String end, {
  String? room,
  String? lecturer,
}) => ScheduleEntry(
  session: ClassSession(
    id: 'k-$name',
    userId: 'u',
    courseId: 'c-$name',
    weekday: weekday,
    startsAt: start,
    endsAt: end,
    createdAt: _now,
    updatedAt: _now,
  ),
  course: Course(
    id: 'c-$name',
    userId: 'u',
    semesterId: 's7',
    name: name,
    room: room,
    lecturer: lecturer,
    createdAt: _now,
    updatedAt: _now,
  ),
);

final _figma = [
  _entry(
    'Pemrograman Mobile',
    DateTime.friday,
    '08:00',
    '09:40',
    room: 'Ruang 301',
    lecturer: 'Bu Rina',
  ),
  _entry(
    'Kecerdasan Buatan',
    DateTime.friday,
    '10:00',
    '11:40',
    room: 'Ruang 204',
    lecturer: 'Pak Andi',
  ),
  _entry('Senin pagi', DateTime.monday, '07:00', '08:40'),
];

void main() {
  test('contoh frame 04: label, Day Pill, kelas hari ini', () {
    final view = buildKuliahView(
      semester: _semester,
      entries: _figma,
      now: _now,
      selectedDay: kuliahDefaultDay(_now),
    );

    expect(view.headerLabel, 'Semester 7 · minggu ke-10');
    expect(view.days.map((d) => (d.dayLabel, d.dateLabel, d.selected)), [
      ('Sen', '2', false),
      ('Sel', '3', false),
      ('Rab', '4', false),
      ('Kam', '5', false),
      ('Jum', '6', true),
      ('Sab', '7', false),
    ]);
    expect(view.dayTitle, 'Jumat, 6 November');
    expect(view.countLabel, '2 kelas');
    expect(view.classes.map((c) => (c.start, c.end, c.meta, c.state)), [
      ('08.00', '09.40', 'Ruang 301 · Bu Rina', AppClassItemState.now),
      ('10.00', '11.40', 'Ruang 204 · Pak Andi', AppClassItemState.upcoming),
    ]);
    expect(view.isEmpty, isFalse);
  });

  test('hari yang lewat = Done, hari esok = Upcoming, tanpa kelas = 0', () {
    KuliahView on(DateTime day) => buildKuliahView(
      semester: _semester,
      entries: _figma,
      now: _now,
      selectedDay: day,
    );

    expect(
      on(DateTime(2026, 11, 2)).classes.single.state,
      AppClassItemState.done,
    );
    final saturday = on(DateTime(2026, 11, 7));
    expect(saturday.classes, isEmpty);
    expect(saturday.countLabel, '0 kelas');

    final late = buildKuliahView(
      semester: _semester,
      entries: _figma,
      now: DateTime(2026, 11, 6, 12),
      selectedDay: DateTime(2026, 11, 6),
    );
    expect(late.classes.map((c) => c.state), [
      AppClassItemState.done,
      AppClassItemState.done,
    ]);
  });

  test('hari Minggu menampilkan minggu depan, Senin terpilih', () {
    final sunday = DateTime(2026, 11, 8, 10);
    final view = buildKuliahView(
      semester: _semester,
      entries: _figma,
      now: sunday,
      selectedDay: kuliahDefaultDay(sunday),
    );
    expect(view.days.first.dateLabel, '9');
    expect(view.days.first.selected, isTrue);
    expect(view.classes.single.state, AppClassItemState.upcoming);
  });

  test('tanpa semester atau tanpa jadwal = K1', () {
    final view = buildKuliahView(
      semester: null,
      entries: const [],
      now: _now,
      selectedDay: _now,
    );
    expect(view.isEmpty, isTrue);
    expect(view.headerLabel, isNull);
  });

  test('semester belum mulai atau tanpa tanggal mulai: tanpa minggu ke', () {
    final noStart = Semester(
      id: 's',
      userId: 'u',
      name: 'Semester 8',
      isActive: true,
      createdAt: _now,
      updatedAt: _now,
    );
    String? label(Semester s) => buildKuliahView(
      semester: s,
      entries: const [],
      now: _now,
      selectedDay: _now,
    ).headerLabel;

    expect(label(noStart), 'Semester 8');
    expect(
      label(noStart.copyWith(startsOn: Value(DateTime(2027, 2)))),
      'Semester 8',
    );
  });
}
