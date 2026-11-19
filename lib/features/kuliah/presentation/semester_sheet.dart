import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';
import 'package:super_app/features/kuliah/application/semester_choices.dart';

/// Buka P20 Pilih semester (Figma 85:4227). Mengembalikan pilihan, atau
/// `null` kalau ditutup.
Future<SemesterChoice?> showSemesterSheet({
  required BuildContext context,
  required SemesterChoices choices,
}) {
  return showAppBottomSheet<SemesterChoice>(
    context: context,
    builder: (_) => SemesterSheet(choices: choices),
  );
}

/// Isi P20: daftar semester (Option Item tanpa ikon) dan "+ Semester baru".
/// Mengetuk pilihan langsung memilih dan menutup sheet.
class SemesterSheet extends StatelessWidget {
  const SemesterSheet({super.key, required this.choices});

  final SemesterChoices choices;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    final next = choices.next;

    return AppBottomSheet(
      title: 'Pilih semester',
      subtitle: 'Jadwal, tugas, dan nilai ikut semester ini',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpace.s8,
        children: [
          for (final choice in choices.options)
            AppOptionItem(
              title: choice.title,
              caption: choice.caption,
              selected: choice.selected,
              onTap: () => navigator.pop(choice),
            ),
        ],
      ),
      footer: [
        if (next != null)
          AppButton(
            label: '+ Semester baru',
            style: AppButtonStyle.ghost,
            onPressed: () => navigator.pop(next),
          ),
      ],
    );
  }
}
