import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';

/// Progress Bar dari Figma (Components [04], node 23:88): tinggi 6,
/// track Surface/Card, isi oranye, berbentuk pil.
///
/// Varian Figma per 10 hanya peraga; di kode nilainya bebas 0–100.
/// Lebar mengikuti induk.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({super.key, required this.value});

  /// Tinggi tetap di Figma.
  static const double height = 6;

  /// Persentase 0–100. Nilai di luar rentang dipotong.
  final double value;

  @override
  Widget build(BuildContext context) {
    final percent = value.clamp(0, 100).toDouble();
    final radius = BorderRadius.circular(AppRadius.full);

    return Semantics(
      value: '${percent.round()}%',
      child: Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: radius,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: percent / 100,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.brandingOrange,
                borderRadius: radius,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
