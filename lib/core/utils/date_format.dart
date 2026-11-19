/// Format tanggal dan jam berbahasa Indonesia, sesuai design-notes §5
/// (jam 08.00, "Jumat 6 Nov"). Tanpa paket intl supaya tidak perlu
/// memuat data locale saat app mulai.
abstract final class AppDateFormat {
  static const List<String> _weekdays = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _weekdaysShort = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  static const List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  /// "07.40".
  static String time(DateTime date) =>
      '${_two(date.hour)}.${_two(date.minute)}';

  /// "Jumat".
  static String weekday(DateTime date) => _weekdays[date.weekday - 1];

  /// "Sen".
  static String weekdayShort(DateTime date) => _weekdaysShort[date.weekday - 1];

  /// "12 Nov".
  static String dayMonthShort(DateTime date) =>
      '${date.day} ${_monthsShort[date.month - 1]}';

  /// "Jumat 6 Nov".
  static String weekdayDayMonth(DateTime date) =>
      '${weekday(date)} ${dayMonthShort(date)}';

  /// "Jumat, 6 November" (judul hari di 04 Kuliah).
  static String weekdayCommaDayMonthLong(DateTime date) =>
      '${weekday(date)}, ${date.day} ${_months[date.month - 1]}';

  /// "Sep 2026" (periode semester di P20).
  static String monthYearShort(DateTime date) =>
      '${_monthsShort[date.month - 1]} ${date.year}';

  /// "Jumat, 6 Nov" (baris tanggal di 16 Detail tugas).
  static String weekdayCommaDayMonth(DateTime date) =>
      '${weekday(date)}, ${dayMonthShort(date)}';

  /// "Jum, 6 Nov" (kolom Tanggal di form 15 dan 17).
  static String weekdayShortDayMonth(DateTime date) =>
      '${weekdayShort(date)}, ${dayMonthShort(date)}';

  /// Tanggal tanpa jam (pukul 00.00), untuk membandingkan hari.
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Selisih hari kalender dari [from] ke [to] (bukan selisih 24 jam).
  /// Besok = 1, kemarin = −1.
  static int daysBetween(DateTime from, DateTime to) {
    final a = dateOnly(from.toLocal());
    final b = dateOnly(to.toLocal());
    return DateTime.utc(
      b.year,
      b.month,
      b.day,
    ).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
