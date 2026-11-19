import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';

/// Page Indicator dari Figma (Components, node 62:1799): titik halaman
/// intro. Halaman aktif berupa pil oranye 24×8, lainnya titik Dark Gray 8.
class AppPageIndicator extends StatelessWidget {
  const AppPageIndicator({super.key, required this.page, this.count = 4});

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _dot = 8;
  static const double _activeWidth = 24;

  /// Halaman aktif, mulai dari 1.
  final int page;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpace.s8,
      children: [
        for (var i = 1; i <= count; i++)
          Container(
            width: i == page ? _activeWidth : _dot,
            height: _dot,
            decoration: BoxDecoration(
              color: i == page ? AppColors.brandingOrange : AppColors.darkGray,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
      ],
    );
  }
}
