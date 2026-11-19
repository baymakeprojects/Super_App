import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_icon.dart';
import 'package:super_app/core/ui/app_label_text.dart';

/// Tipe Banner di Figma.
enum AppBannerType {
  /// Offline, sinkron tertunda (ikon Refresh kuning).
  warning,

  /// Gagal (ikon Close merah).
  danger,

  /// Info atau mode senyap (ikon Bell oranye).
  info,

  /// Berhasil (ikon Check hijau).
  success,
}

/// Banner dari Figma (Components [11], node 65:226): pemberitahuan yang
/// bertahan di bawah header, di atas isi (offline, sinkron gagal).
/// Garis dan ikon berwarna tipe, latar diberi tint tipis warna yang sama.
class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.type,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _iconSize = 20;
  static const double _borderWidth = 1;

  /// Tint warna tipe di atas latar: opacity 8% di Figma.
  static const double _tintOpacity = 0.08;

  final AppBannerType type;
  final String title;

  /// Keterangan abu di bawah judul. `null` = disembunyikan.
  final String? body;

  /// Aksi kapital di kanan, misalnya "Coba lagi". `null` = disembunyikan.
  final String? actionLabel;
  final VoidCallback? onAction;

  (Color, AppIcons) get _style => switch (type) {
    AppBannerType.warning => (AppColors.warning, AppIcons.refresh),
    AppBannerType.danger => (AppColors.danger, AppIcons.close),
    AppBannerType.info => (AppColors.brandingOrange, AppIcons.bell),
    AppBannerType.success => (AppColors.success, AppIcons.check),
  };

  /// Warna teks aksi: tipe Info memakai Accent Text, lainnya warna tipe.
  Color get _actionColor =>
      type == AppBannerType.info ? AppColors.accentText : _style.$1;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _style;
    final body = this.body;
    final actionLabel = this.actionLabel;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s16,
        vertical: AppSpace.s12,
      ),
      decoration: BoxDecoration(
        // Tint di atas Surface/Raised, seperti lapisan "Tint" di Figma.
        color: Color.alphaBlend(
          color.withValues(alpha: _tintOpacity),
          AppColors.surfaceRaised,
        ),
        border: Border.all(color: color, width: _borderWidth),
        borderRadius: BorderRadius.circular(AppRadius.item),
      ),
      child: Row(
        spacing: AppSpace.s12,
        children: [
          AppIcon(icon, size: _iconSize, color: color),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpace.s4,
              children: [
                Text(
                  title,
                  style: AppText.bodyMedium.copyWith(color: AppColors.white),
                ),
                if (body != null)
                  Text(
                    body,
                    style: AppText.bodySmall.copyWith(
                      color: AppColors.lightGray,
                    ),
                  ),
              ],
            ),
          ),
          if (actionLabel != null)
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onAction,
                child: AppLabelText(
                  actionLabel,
                  style: AppText.labelSmall.copyWith(color: _actionColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
