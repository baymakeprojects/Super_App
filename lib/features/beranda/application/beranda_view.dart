import 'package:super_app/core/utils/date_format.dart';
import 'package:super_app/features/kuliah/data/course_repository.dart';

/// Kelas berikutnya di kartu oranye Beranda.
class NextClass {
  const NextClass({
    required this.courseId,
    required this.course,
    required this.countdown,
    required this.meta,
  });

  final String courseId;
  final String course;

  /// "25 menit lagi", "1 jam 25 menit lagi".
  final String countdown;

  /// "08.00–09.40 · Ruang 301 · Bu Rina".
  final String meta;
}

/// Kelas hari ini yang paling dekat dan belum mulai. `null` = tidak ada
/// kelas lagi hari ini, kartu disembunyikan (design-notes §6).
NextClass? nextClassOf(List<ScheduleEntry> entries, DateTime now) {
  final nowMinutes = now.hour * Duration.minutesPerHour + now.minute;
  ScheduleEntry? best;
  var bestStart = 0;
  for (final entry in entries) {
    if (entry.session.weekday != now.weekday) continue;
    final start = _minutes(entry.session.startsAt);
    if (start <= nowMinutes) continue;
    if (best == null || start < bestStart) {
      best = entry;
      bestStart = start;
    }
  }
  if (best == null) return null;

  final session = best.session;
  return NextClass(
    courseId: best.course.id,
    course: best.course.name,
    countdown: countdownLabel(bestStart - nowMinutes),
    meta: [
      '${CourseRepository.displayTime(session.startsAt)}–'
          '${CourseRepository.displayTime(session.endsAt)}',
      ?best.room,
      ?best.course.lecturer,
    ].join(' · '),
  );
}

/// "25 menit lagi"; satu jam atau lebih "1 jam 25 menit lagi" / "2 jam
/// lagi" (keputusan Bayu, W3-06, F-45).
String countdownLabel(int minutes) {
  final hours = minutes ~/ Duration.minutesPerHour;
  final rest = minutes % Duration.minutesPerHour;
  if (hours == 0) return '$minutes menit lagi';
  if (rest == 0) return '$hours jam lagi';
  return '$hours jam $rest menit lagi';
}

/// Senin minggu ini (awal "minggu ini" di Stat Card Saldo).
DateTime weekStartOf(DateTime now) {
  final today = AppDateFormat.dateOnly(now);
  return DateTime(
    today.year,
    today.month,
    today.day - (today.weekday - DateTime.monday),
  );
}

/// Huruf awal nama untuk avatar ("Bayu" → "B"). `null` = tanpa nama.
String? initialOf(String? name) {
  final trimmed = name?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed.substring(0, 1).toUpperCase();
}

int _minutes(String hhmm) {
  final parts = hhmm.split(':');
  return int.parse(parts[0]) * Duration.minutesPerHour + int.parse(parts[1]);
}
