import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_icon.dart';

/// FAB dari Figma (Components [02], node 6:27): tombol tambah cepat
/// 56×56, oranye, sudut 12, ikon Plus hitam.
///
/// Hanya dipasang di layar yang punya FAB di Figma.
class AppFab extends StatelessWidget {
  const AppFab({
    super.key,
    required this.onPressed,
    required this.semanticLabel,
  });

  /// Ukuran tetap di Figma.
  static const double size = 56;

  final VoidCallback onPressed;

  /// Teks untuk pembaca layar, misalnya "Tugas baru". Tidak tampil di layar.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brandingOrange,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: const AppIcon(AppIcons.plus, color: AppColors.onAccent),
          ),
        ),
      ),
    );
  }
}
