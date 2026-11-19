import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/utils/date_format.dart';

/// Periode kuliah: Ganjil (Sep–Jan) atau Genap (Feb–Jul) satu tahun
/// akademik, seperti di P20 ("Semester 7 · Ganjil 2026/2027").
///
/// Batas bulan tidak ada di Figma; dipilih dari contoh P20 (Ganjil
/// "Sep 2026 – Jan 2027", Genap "Mulai Feb 2027"). Keputusan Bayu, W2-09,
/// F-39.
class AcademicTerm {
  const AcademicTerm({required this.ganjil, required this.startYear});

  /// Periode yang sedang berjalan atau berikutnya pada [date]. Agustus
  /// dihitung Ganjil yang akan datang.
  factory AcademicTerm.of(DateTime date) {
    if (date.month >= DateTime.august) {
      return AcademicTerm(ganjil: true, startYear: date.year);
    }
    if (date.month == DateTime.january) {
      return AcademicTerm(ganjil: true, startYear: date.year - 1);
    }
    return AcademicTerm(ganjil: false, startYear: date.year - 1);
  }

  /// `true` = Ganjil, `false` = Genap.
  final bool ganjil;

  /// Tahun awal tahun akademik (2026 untuk 2026/2027).
  final int startYear;

  DateTime get startsOn => ganjil
      ? DateTime(startYear, DateTime.september)
      : DateTime(startYear + 1, DateTime.february);

  /// Hari terakhir periode.
  DateTime get endsOn => ganjil
      ? DateTime(startYear + 1, DateTime.january, 31)
      : DateTime(startYear + 1, DateTime.july, 31);

  /// "Ganjil 2026/2027".
  String get label =>
      '${ganjil ? 'Ganjil' : 'Genap'} $startYear/${startYear + 1}';

  /// Periode setelah ini.
  AcademicTerm get next => ganjil
      ? AcademicTerm(ganjil: false, startYear: startYear)
      : AcademicTerm(ganjil: true, startYear: startYear + 1);

  @override
  bool operator ==(Object other) =>
      other is AcademicTerm &&
      other.ganjil == ganjil &&
      other.startYear == startYear;

  @override
  int get hashCode => Object.hash(ganjil, startYear);
}

/// Nomor semester dari nama "Semester 7", `null` kalau tidak ada angkanya.
int? semesterNumber(String name) {
  final match = RegExp(r'(\d+)').firstMatch(name);
  return match == null ? null : int.parse(match.group(1)!);
}

/// Judul semester di P20: "Semester 7 · Ganjil 2026/2027".
String semesterTitle(Semester semester) {
  final startsOn = semester.startsOn;
  if (startsOn == null) return semester.name;
  return '${semester.name} · ${AcademicTerm.of(startsOn).label}';
}

/// Keterangan semester di P20, dari contoh Figma:
/// "Sep 2026 – Jan 2027 · sedang berjalan", "Mulai Feb 2027", "Selesai".
/// IPS di contoh Figma termasuk fitur nilai (Tahap 2), jadi tidak ditampilkan.
String? semesterCaption({
  required DateTime? startsOn,
  required DateTime? endsOn,
  required DateTime today,
}) {
  if (startsOn == null) return null;
  final day = AppDateFormat.dateOnly(today);
  if (day.isBefore(startsOn)) {
    return 'Mulai ${AppDateFormat.monthYearShort(startsOn)}';
  }
  if (endsOn != null && day.isAfter(endsOn)) return 'Selesai';
  final range = endsOn == null
      ? AppDateFormat.monthYearShort(startsOn)
      : '${AppDateFormat.monthYearShort(startsOn)} – '
            '${AppDateFormat.monthYearShort(endsOn)}';
  return '$range · sedang berjalan';
}
