import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';

/// Switch dari Figma (Components [03], node 6:68): pil 46×26 dengan knob 20.
/// Off: isi Surface/Card, garis Dark Gray, knob Gray di kiri.
/// On: isi dan garis oranye, knob hitam di kanan.
///
/// Tanpa animasi geser, karena Figma tidak menunjukkan animasi.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
  });

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _width = 46;
  static const double _height = 26;
  static const double _knobSize = 20;
  static const double _borderWidth = 1;

  final bool value;

  /// `null` = tidak bisa diubah.
  final ValueChanged<bool>? onChanged;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;

    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged(!value),
        child: SizedBox(
          width: _width,
          height: _height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: value ? AppColors.brandingOrange : AppColors.surfaceCard,
              border: Border.all(
                color: value ? AppColors.brandingOrange : AppColors.darkGray,
                width: _borderWidth,
              ),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: value ? _width - AppSpace.s4 - _knobSize : AppSpace.s4,
                  top: (_height - _knobSize) / 2,
                  child: Container(
                    width: _knobSize,
                    height: _knobSize,
                    decoration: BoxDecoration(
                      color: value ? AppColors.onAccent : AppColors.gray,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
