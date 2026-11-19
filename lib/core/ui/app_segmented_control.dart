import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_label_text.dart';

/// Segmented Control dari Figma (Components [07], node 21:62): dua pilihan,
/// misalnya Pengeluaran / Pemasukan. Segmen terpilih isi oranye.
class AppSegmentedControl extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.firstLabel,
    required this.secondLabel,
    required this.selectedIndex,
    required this.onChanged,
  });

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _segmentRadius = 8;
  static const double _borderWidth = 1;

  final String firstLabel;
  final String secondLabel;

  /// 0 = pilihan pertama, 1 = pilihan kedua.
  final int selectedIndex;

  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.s4),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border.all(color: AppColors.darkGray, width: _borderWidth),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Row(
        spacing: AppSpace.s4,
        children: [
          for (final (index, label) in [(0, firstLabel), (1, secondLabel)])
            Expanded(child: _segment(index, label)),
        ],
      ),
    );
  }

  Widget _segment(int index, String label) {
    final selected = index == selectedIndex;
    final onChanged = this.onChanged;

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onChanged == null ? null : () => onChanged(index),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s16,
            vertical: AppSpace.s12,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandingOrange : null,
            borderRadius: BorderRadius.circular(_segmentRadius),
          ),
          // heightFactor 1: tengah secara horizontal tanpa ikut memanjang ke
          // bawah.
          child: Center(
            heightFactor: 1,
            child: AppLabelText(
              label,
              style: AppText.labelMedium.copyWith(
                color: selected ? AppColors.onAccent : AppColors.lightGray,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
