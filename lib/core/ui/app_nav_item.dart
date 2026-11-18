import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_icon.dart';
import 'package:super_app/core/ui/app_label_text.dart';

/// Nav Item dari Figma (Components [05], node 7:43): satu tab di Bottom Nav.
/// Active: ikon, label, dan garis pendek di atas ikon berwarna oranye.
///
/// Lebar mengikuti induk (di Bottom Nav, lima tab berbagi lebar sama).
class AppNavItem extends StatelessWidget {
  const AppNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _indicatorWidth = 24;
  static const double _indicatorHeight = 2;
  static const double _indicatorGap = 6;

  final AppIcons icon;

  /// Nama tab. Dikapitalkan otomatis.
  final String label;

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.brandingOrange : AppColors.gray;

    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.s8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.s4,
            children: [
              Container(
                width: _indicatorWidth,
                height: _indicatorHeight,
                color: active ? AppColors.brandingOrange : null,
              ),
              const SizedBox(height: _indicatorGap),
              AppIcon(icon, color: color),
              AppLabelText(
                label,
                style: AppText.labelSmall.copyWith(
                  color: active ? AppColors.accentText : AppColors.gray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
