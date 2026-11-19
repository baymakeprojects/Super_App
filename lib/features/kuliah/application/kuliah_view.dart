import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/ui/app_class_item.dart';
import 'package:super_app/core/utils/date_format.dart';
import 'package:super_app/features/kuliah/data/course_repository.dart';

/// Satu Day Pill di 04.
class DayPillView {
  const DayPillView({
    required this.date,
    required this.dayLabel,
    required this.dateLabel,
    required this.selected,
  });

  final DateTime date;

  /// "Sen".
  final String dayLabel;

  /// "2".
  final String dateLabel;
  final bool selected;
}

/// Satu kelas di 04, siap tampil.
class ClassRowView {
  const ClassRowView({
    required this.courseId,
    required this.start,
    required this.end,
    required this.course,
    required this.meta,
    required this.state,
  });

  final String courseId;
  final String start;
  final String end;
  final String course;

  /// "Ruang 301 · Bu Rina".
  final String meta;
  final AppClassItemState state;
}

/// Isi layar 04 Kuliah / K1.
class KuliahView {
  const KuliahView({
    required this.headerLabel,
    required this.days,
    required this.dayTitle,
    required this.countLabel,
    required this.classes,
    required this.isEmpty,
  });

  /// "Semester 7 · minggu ke-10". `null` = belum ada semester aktif
  /// (baris disembunyikan, F-37).
  final String? headerLabel;

  /// Senin–Sabtu minggu ini, seperti Figma.
  final List<DayPillView> days;

  /// "Jumat, 6 November".
  final String dayTitle;

  /// "3 kelas".
  final String countLabel;

  final List<ClassRowView> classes;

  /// `true` = semester belum punya jadwal sama sekali → K1.
  final bool isEmpty;
}

/// Hari yang tampil di Day Pill: Senin–Sabtu (Figma 04 tanpa Minggu).
const int _pillDays = 6;

/// Senin minggu yang tampil. Hari Minggu menampilkan minggu berikutnya,
/// karena Minggu tidak punya Day Pill (keputusan Bayu, W2-08, F-37).
DateTime kuliahWeekStart(DateTime now) {
  final today = AppDateFormat.dateOnly(now);
  if (today.weekday == DateTime.sunday) {
    return DateTime(today.year, today.month, today.day + 1);
  }
  return DateTime(
    today.year,
    today.month,
    today.day - (today.weekday - DateTime.monday),
  );
}

/// Hari terpilih bawaan: hari ini, atau Senin kalau hari ini Minggu.
DateTime kuliahDefaultDay(DateTime now) {
  final today = AppDateFormat.dateOnly(now);
  return today.weekday == DateTime.sunday ? kuliahWeekStart(now) : today;
}

/// Aturan layar 04 (design-notes §6, keputusan Bayu W2-08):
///
/// - Label atas: nama semester aktif + "minggu ke-n" dihitung dari tanggal
///   mulai semester (minggu pertama = ke-1).
/// - Keadaan kelas: hari yang sudah lewat = Done, hari yang akan datang =
///   Upcoming; hari ini menurut jam (Now selama kelas berlangsung).
KuliahView buildKuliahView({
  required Semester? semester,
  required List<ScheduleEntry> entries,
  required DateTime now,
  required DateTime selectedDay,
}) {
  final weekStart = kuliahWeekStart(now);
  final selected = AppDateFormat.dateOnly(selectedDay);
  final today = AppDateFormat.dateOnly(now);

  final classes = [
    for (final entry in entries)
      if (entry.session.weekday == selected.weekday)
        ClassRowView(
          courseId: entry.course.id,
          start: CourseRepository.displayTime(entry.session.startsAt),
          end: CourseRepository.displayTime(entry.session.endsAt),
          course: entry.course.name,
          meta: [?entry.room, ?entry.course.lecturer].join(' · '),
          state: _stateOf(entry.session, selected, today, now),
        ),
  ];

  return KuliahView(
    headerLabel: _headerLabel(semester, today),
    days: [
      for (var i = 0; i < _pillDays; i++)
        _pill(
          DateTime(weekStart.year, weekStart.month, weekStart.day + i),
          selected,
        ),
    ],
    dayTitle: AppDateFormat.weekdayCommaDayMonthLong(selected),
    countLabel: '${classes.length} kelas',
    classes: classes,
    isEmpty: entries.isEmpty,
  );
}

DayPillView _pill(DateTime date, DateTime selected) => DayPillView(
  date: date,
  dayLabel: AppDateFormat.weekdayShort(date),
  dateLabel: '${date.day}',
  selected: AppDateFormat.daysBetween(date, selected) == 0,
);

String? _headerLabel(Semester? semester, DateTime today) {
  if (semester == null) return null;
  final startsOn = semester.startsOn;
  if (startsOn == null) return semester.name;
  final days = AppDateFormat.daysBetween(startsOn, today);
  if (days < 0) return semester.name;
  final week = days ~/ DateTime.daysPerWeek + 1;
  return '${semester.name} · minggu ke-$week';
}

AppClassItemState _stateOf(
  ClassSession session,
  DateTime day,
  DateTime today,
  DateTime now,
) {
  final days = AppDateFormat.daysBetween(today, day);
  if (days < 0) return AppClassItemState.done;
  if (days > 0) return AppClassItemState.upcoming;

  final minutes = now.hour * Duration.minutesPerHour + now.minute;
  if (minutes < _minutesOf(session.startsAt)) return AppClassItemState.upcoming;
  if (minutes < _minutesOf(session.endsAt)) return AppClassItemState.now;
  return AppClassItemState.done;
}

/// Menit sejak tengah malam dari jam `HH:mm`.
int _minutesOf(String hhmm) {
  final parts = hhmm.split(':');
  return int.parse(parts[0]) * Duration.minutesPerHour + int.parse(parts[1]);
}
