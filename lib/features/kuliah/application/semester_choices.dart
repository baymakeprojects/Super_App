import 'package:super_app/features/kuliah/application/academic_term.dart';
import 'package:super_app/features/kuliah/data/semester_repository.dart';

/// Satu pilihan di P20 Pilih semester. [id] `null` = semester yang belum
/// tersimpan (dibuat saat dipilih).
class SemesterChoice {
  const SemesterChoice({
    required this.id,
    required this.name,
    required this.startsOn,
    required this.endsOn,
    required this.title,
    required this.caption,
    required this.selected,
  });

  final String? id;

  /// "Semester 7".
  final String name;
  final DateTime? startsOn;
  final DateTime? endsOn;

  /// "Semester 7 · Ganjil 2026/2027".
  final String title;

  /// "Sep 2026 – Jan 2027 · sedang berjalan".
  final String? caption;
  final bool selected;
}

/// Isi P20.
class SemesterChoices {
  const SemesterChoices({required this.options, required this.next});

  final List<SemesterChoice> options;

  /// Semester untuk tombol "+ Semester baru". `null` = tombol disembunyikan
  /// (belum ada semester: pilihan sudah berisi semester periode ini).
  final SemesterChoice? next;
}

/// Jumlah semester yang ditawarkan saat belum ada semester sama sekali:
/// semester ganjil 1–13 untuk periode Ganjil, genap 2–14 untuk Genap.
const int _offeredSemesters = 7;

/// Pilihan P20 (keputusan Bayu, W2-09, F-39):
///
/// - Sudah ada semester: semester aktif dulu, lalu yang lain terbaru dulu.
///   "+ Semester baru" = nomor berikutnya di periode berikutnya.
/// - Belum ada semester: Semester 1, 3, 5, … (atau 2, 4, 6, …) untuk
///   periode yang sedang berjalan, supaya cukup sekali ketuk.
Future<SemesterChoices> loadSemesterChoices(
  SemesterRepository repository, {
  required DateTime today,
}) async {
  final semesters = await repository.getSemesters();

  SemesterChoice candidate(int number, AcademicTerm term) => SemesterChoice(
    id: null,
    name: 'Semester $number',
    startsOn: term.startsOn,
    endsOn: term.endsOn,
    title: 'Semester $number · ${term.label}',
    caption: semesterCaption(
      startsOn: term.startsOn,
      endsOn: term.endsOn,
      today: today,
    ),
    selected: false,
  );

  if (semesters.isEmpty) {
    final term = AcademicTerm.of(today);
    final first = term.ganjil ? 1 : 2;
    return SemesterChoices(
      options: [
        for (var i = 0; i < _offeredSemesters; i++)
          candidate(first + 2 * i, term),
      ],
      next: null,
    );
  }

  final ordered = [
    ...semesters.where((s) => s.isActive),
    ...semesters.where((s) => !s.isActive),
  ];
  final latest = semesters.first; // getSemesters: terbaru dulu
  final latestStart = latest.startsOn;
  final nextTerm = latestStart == null
      ? AcademicTerm.of(today)
      : AcademicTerm.of(latestStart).next;
  final nextNumber = (semesterNumber(latest.name) ?? semesters.length) + 1;

  return SemesterChoices(
    options: [
      for (final s in ordered)
        SemesterChoice(
          id: s.id,
          name: s.name,
          startsOn: s.startsOn,
          endsOn: s.endsOn,
          title: semesterTitle(s),
          caption: semesterCaption(
            startsOn: s.startsOn,
            endsOn: s.endsOn,
            today: today,
          ),
          selected: s.isActive,
        ),
    ],
    next: candidate(nextNumber, nextTerm),
  );
}

/// Simpan pilihan P20 sebagai semester aktif. Mengembalikan id semester.
Future<String> activateSemesterChoice(
  SemesterRepository repository,
  SemesterChoice choice,
) async {
  final id = choice.id;
  if (id != null) {
    await repository.setActiveSemester(id);
    return id;
  }
  return repository.addSemester(
    name: choice.name,
    startsOn: choice.startsOn,
    endsOn: choice.endsOn,
    active: true,
  );
}
