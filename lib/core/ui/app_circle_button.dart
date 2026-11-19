import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_icon.dart';

/// Tombol ikon bulat 40 dengan garis Dark Gray, ikon 20 di tengah.
///
/// Dipakai di kepala menu utama (Cari di 03, Notifikasi di 02, + di 04).
/// Di Figma ini frame berulang di layar, belum jadi komponen (F-22).
class AppCircleButton extends StatelessWidget {
  const AppCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.iconColor = AppColors.white,
  });

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double size = 40;
  static const double _iconSize = 20;
  static const double _borderWidth = 1;

  final AppIcons icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.darkGray, width: _borderWidth),
          ),
          child: AppIcon(icon, size: _iconSize, color: iconColor),
        ),
      ),
    );
  }
}
