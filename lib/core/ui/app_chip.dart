import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_label_text.dart';

/// Chip dari Figma (Components [03], node 6:75): pil untuk filter dan
/// pilihan. Selected = isi oranye, teks hitam.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const double _borderWidth = 1;

  /// Teks chip, disalin dari Figma atau dari data. Dikapitalkan otomatis.
  final String label;

  final bool selected;

  /// `null` = tidak bisa dipilih.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s12,
            vertical: AppSpace.s8,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandingOrange : null,
            border: Border.all(
              color: selected ? AppColors.brandingOrange : AppColors.darkGray,
              width: _borderWidth,
            ),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: AppLabelText(
            label,
            style: AppText.labelMedium.copyWith(
              color: selected ? AppColors.onAccent : AppColors.lightGray,
            ),
          ),
        ),
      ),
    );
  }
}
