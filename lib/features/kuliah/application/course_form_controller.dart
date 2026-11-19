import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:super_app/core/db/app_database.dart';
import 'package:super_app/core/utils/clock.dart';
import 'package:super_app/features/kuliah/data/course_repository.dart';
import 'package:super_app/features/kuliah/data/course_repository_provider.dart';

/// Isian H02 Jadwal baru / Ubah jadwal.
class CourseFormState {
  const CourseFormState({
    required this.name,
    required this.lecturer,
    required this.room,
    required this.credits,
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
    required this.showNameError,
    required this.showTimeError,
    required this.saving,
  });

  final String name;
  final String lecturer;
  final String room;

  /// `null` = tidak ada chip SKS terpilih (mata kuliah lama tanpa SKS).
  final int? credits;

  /// 1 = Senin … 6 = Sabtu.
  final int weekday;

  /// Jam mulai dan selesai, dalam menit sejak tengah malam.
  final int startMinutes;
  final int endMinutes;

  /// Nama kosong saat Simpan (pola G2).
  final bool showNameError;

  /// Jam selesai tidak setelah jam mulai saat Simpan (F-38).
  final bool showTimeError;

  final bool saving;

  CourseFormState copyWith({
    String? name,
    String? lecturer,
    String? room,
    int? credits,
    int? weekday,
    int? startMinutes,
    int? endMinutes,
    bool? showNameError,
    bool? showTimeError,
    bool? saving,
  }) {
    return CourseFormState(
      name: name ?? this.name,
      lecturer: lecturer ?? this.lecturer,
      room: room ?? this.room,
      credits: credits ?? this.credits,
      weekday: weekday ?? this.weekday,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
      showNameError: showNameError ?? this.showNameError,
      showTimeError: showTimeError ?? this.showTimeError,
      saving: saving ?? this.saving,
    );
  }
}

/// "HH:mm" (kolom database) dari menit sejak tengah malam.
String minutesToColumn(int minutes) =>
    '${_two(minutes ~/ Duration.minutesPerHour)}:'
    '${_two(minutes % Duration.minutesPerHour)}';

/// "13.00" (tampilan) dari menit sejak tengah malam.
String minutesToDisplay(int minutes) =>
    minutesToColumn(minutes).replaceFirst(':', '.');

/// Menit sejak tengah malam dari kolom "HH:mm".
int columnToMinutes(String hhmm) {
  final parts = hhmm.split(':');
  return int.parse(parts[0]) * Duration.minutesPerHour + int.parse(parts[1]);
}

String _two(int value) => value.toString().padLeft(2, '0');

/// Data awal mode ubah: mata kuliah dan jadwal pertamanya.
class CourseEditSource {
  const CourseEditSource({required this.course, required this.session});

  final Course course;
  final ClassSession? session;
}

/// Isian awal Ubah jadwal, dibaca sekali. `null` = tidak ada / dihapus.
final courseEditSourceProvider = FutureProvider.autoDispose
    .family<CourseEditSource?, String>((ref, id) async {
      final repository = ref.read(courseRepositoryProvider);
      final course = await repository.getCourse(id);
      if (course == null) return null;
      final sessions = await repository.getSessions(id);
      return CourseEditSource(
        course: course,
        session: sessions.isEmpty ? null : sessions.first,
      );
    });

/// Form H02. Argumen `null` = Jadwal baru; id mata kuliah = Ubah jadwal
/// (pastikan [courseEditSourceProvider] untuk id itu sudah selesai dibaca).
final courseFormProvider = NotifierProvider.autoDispose
    .family<CourseFormController, CourseFormState, String?>(
      CourseFormController.new,
    );

class CourseFormController extends Notifier<CourseFormState> {
  CourseFormController(this.courseId);

  /// `null` = mata kuliah baru.
  final String? courseId;

  // Isian awal (keputusan Bayu, W2-09, F-38): 3 SKS seperti contoh Figma,
  // kelas 08.00–09.40 (100 menit).
  static const int defaultCredits = 3;
  static const int defaultStart = 8 * Duration.minutesPerHour;
  static const int defaultDuration = 100;

  @override
  CourseFormState build() {
    final courseId = this.courseId;
    if (courseId != null) {
      final source = ref.read(courseEditSourceProvider(courseId)).value;
      if (source != null) return _fromCourse(source);
    }

    final today = ref.read(clockProvider)();
    return CourseFormState(
      name: '',
      lecturer: '',
      room: '',
      credits: defaultCredits,
      // Hari ini; hari Minggu (tanpa pilihan) jadi Senin.
      weekday: today.weekday == DateTime.sunday
          ? DateTime.monday
          : today.weekday,
      startMinutes: defaultStart,
      endMinutes: defaultStart + defaultDuration,
      showNameError: false,
      showTimeError: false,
      saving: false,
    );
  }

  static CourseFormState _fromCourse(CourseEditSource source) {
    final course = source.course;
    final session = source.session;
    final start = session == null
        ? defaultStart
        : columnToMinutes(session.startsAt);
    return CourseFormState(
      name: course.name,
      lecturer: course.lecturer ?? '',
      room: session?.room ?? course.room ?? '',
      credits: course.credits,
      weekday: session?.weekday ?? DateTime.monday,
      startMinutes: start,
      endMinutes: session == null
          ? start + defaultDuration
          : columnToMinutes(session.endsAt),
      showNameError: false,
      showTimeError: false,
      saving: false,
    );
  }

  void setName(String name) =>
      state = state.copyWith(name: name, showNameError: false);

  void setLecturer(String lecturer) =>
      state = state.copyWith(lecturer: lecturer);

  void setRoom(String room) => state = state.copyWith(room: room);

  void setCredits(int credits) => state = state.copyWith(credits: credits);

  void setWeekday(int weekday) => state = state.copyWith(weekday: weekday);

  /// Jam mulai baru; jam selesai ikut bergeser dengan durasi yang sama
  /// (keputusan Bayu, W2-09).
  void setStart(int minutes) {
    final duration = state.endMinutes - state.startMinutes;
    final end = minutes + (duration > 0 ? duration : defaultDuration);
    state = state.copyWith(
      startMinutes: minutes,
      endMinutes: end.clamp(0, Duration.minutesPerDay - 1),
      showTimeError: false,
    );
  }

  void setEnd(int minutes) =>
      state = state.copyWith(endMinutes: minutes, showTimeError: false);

  /// Periksa isian; pesan muncul di kolomnya. `true` = boleh disimpan.
  bool validate() {
    final nameMissing = state.name.trim().isEmpty;
    final timeWrong = state.endMinutes <= state.startMinutes;
    state = state.copyWith(
      showNameError: nameMissing,
      showTimeError: timeWrong,
    );
    return !nameMissing && !timeWrong;
  }

  /// Simpan. [semesterId] wajib untuk mata kuliah baru. Mengembalikan id
  /// mata kuliah, atau `null` kalau isian belum lengkap.
  Future<String?> save({String? semesterId}) async {
    if (state.saving || !validate()) return null;
    state = state.copyWith(saving: true);
    try {
      String? text(String value) {
        final trimmed = value.trim();
        return trimmed.isEmpty ? null : trimmed;
      }

      final CourseInput input = (
        name: state.name.trim(),
        lecturer: text(state.lecturer),
        room: text(state.room),
        credits: state.credits,
        weekday: state.weekday,
        startsAt: minutesToColumn(state.startMinutes),
        endsAt: minutesToColumn(state.endMinutes),
      );
      final repository = ref.read(courseRepositoryProvider);
      final courseId = this.courseId;
      if (courseId == null) {
        return await repository.addCourse(
          semesterId: semesterId!,
          input: input,
        );
      }
      await repository.updateCourse(courseId, input: input);
      return courseId;
    } finally {
      if (ref.mounted) state = state.copyWith(saving: false);
    }
  }
}
