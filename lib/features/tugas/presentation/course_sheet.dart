import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/features/kuliah/data/course_repository.dart';

/// Hasil P03. [course] `null` = "Tanpa mata kuliah".
class PickedCourse {
  const PickedCourse(this.course);

  final CourseOption? course;
}

/// Hasil tombol "+ Tambah mata kuliah": layar pemanggil membuka H02.
class AddCourseRequested {
  const AddCourseRequested();
}

/// Buka P03 Pilih mata kuliah (Figma 50:483). Mengembalikan [PickedCourse],
/// [AddCourseRequested], atau `null` kalau ditutup.
Future<Object?> showCourseSheet({
  required BuildContext context,
  required CourseOptions options,
  required String? selectedId,
}) {
  return showAppBottomSheet<Object>(
    context: context,
    builder: (_) => CourseSheet(options: options, selectedId: selectedId),
  );
}

/// Isi P03: daftar mata kuliah semester aktif + "Tanpa mata kuliah".
/// Mengetuk pilihan langsung memilih dan menutup sheet (tanpa tombol
/// Pilih, seperti di Figma).
class CourseSheet extends StatelessWidget {
  const CourseSheet({
    super.key,
    required this.options,
    required this.selectedId,
  });

  final CourseOptions options;

  /// `null` = "Tanpa mata kuliah" yang terpilih.
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    final semester = options.semesterName;
    final navigator = Navigator.of(context);

    return AppBottomSheet(
      title: 'Mata kuliah',
      // Tanpa semester aktif cukup "Ketuk untuk memilih" (keputusan Bayu,
      // W2-05, F-30).
      subtitle: semester == null
          ? 'Ketuk untuk memilih'
          : '$semester · ketuk untuk memilih',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpace.s8,
        children: [
          for (final course in options.courses)
            AppOptionItem(
              icon: AppIcons.learn,
              title: course.name,
              caption: course.caption,
              selected: course.id == selectedId,
              onTap: () => navigator.pop(PickedCourse(course)),
            ),
          AppOptionItem(
            icon: AppIcons.task,
            title: 'Tanpa mata kuliah',
            caption: 'Tugas pribadi atau skripsi',
            selected: selectedId == null,
            onTap: () => navigator.pop(const PickedCourse(null)),
          ),
        ],
      ),
      footer: [
        AppButton(
          label: '+ Tambah mata kuliah',
          style: AppButtonStyle.ghost,
          onPressed: () => navigator.pop(const AddCourseRequested()),
        ),
      ],
    );
  }
}
