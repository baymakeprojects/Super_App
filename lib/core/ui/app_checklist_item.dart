import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_checkbox.dart';

/// Checklist Item dari Figma (Components [07], node 21:112): sub-tugas dan
/// topik belajar. Done: checkbox oranye, teks abu.
class AppChecklistItem extends StatelessWidget {
  const AppChecklistItem({
    super.key,
    required this.label,
    required this.done,
    required this.onChanged,
  });

  final String label;
  final bool done;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null ? null : () => onChanged(!done),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.s8),
        child: Row(
          spacing: AppSpace.s12,
          children: [
            AppCheckbox(value: done, onChanged: onChanged),
            Expanded(
              child: Text(
                label,
                style: AppText.bodyMedium.copyWith(
                  color: done ? AppColors.gray : AppColors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
