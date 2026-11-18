import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_icon.dart';

/// Checkbox dari Figma (Components [03], node 6:61): kotak 24×24, sudut 6.
/// Dicentang = isi oranye, centang hitam.
///
/// Catatan Figma: di layar, bungkus dengan padding 12 supaya area sentuh
/// cukup besar (48×48).
class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _size = 24;
  static const double _radius = 6;
  static const double _borderWidth = 1.5;
  static const double _checkSize = 18;

  final bool value;

  /// `null` = tidak bisa diubah.
  final ValueChanged<bool>? onChanged;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    final color = value ? AppColors.brandingOrange : AppColors.gray;

    return Semantics(
      checked: value,
      enabled: onChanged != null,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged(!value),
        child: Container(
          width: _size,
          height: _size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: value ? AppColors.brandingOrange : null,
            border: Border.all(color: color, width: _borderWidth),
            borderRadius: BorderRadius.circular(_radius),
          ),
          child: value
              ? const AppIcon(
                  AppIcons.check,
                  color: AppColors.onAccent,
                  size: _checkSize,
                )
              : null,
        ),
      ),
    );
  }
}
