import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_label_text.dart';

/// Tipe Badge di Figma (Components [03], node 6:86).
///
/// Menurut design-notes: Terlambat = danger, Hari ini = warning,
/// Selesai dan Lunas = success, Besok dan "3 hari" = neutral.
enum AppBadgeType { neutral, success, warning, danger }

/// Label status kecil berbentuk pil, teks Geist Mono kapital.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.type = AppBadgeType.neutral,
  });

  /// Latar status di Figma: warna status dengan opacity 20%.
  static const double _tintOpacity = 0.2;

  /// Teks badge. Dikapitalkan otomatis.
  final String label;

  final AppBadgeType type;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (type) {
      AppBadgeType.neutral => (AppColors.surfaceCard, AppColors.lightGray),
      AppBadgeType.success => (
        AppColors.success.withValues(alpha: _tintOpacity),
        AppColors.success,
      ),
      AppBadgeType.warning => (
        AppColors.warning.withValues(alpha: _tintOpacity),
        AppColors.warning,
      ),
      AppBadgeType.danger => (
        AppColors.danger.withValues(alpha: _tintOpacity),
        AppColors.danger,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s8,
        vertical: AppSpace.s4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: AppLabelText(
        label,
        style: AppText.labelSmall.copyWith(color: foreground),
      ),
    );
  }
}
