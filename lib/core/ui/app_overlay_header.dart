import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_icon.dart';

/// Tipe Overlay Header di Figma.
enum AppOverlayHeaderType {
  /// Bottom sheet HP: ada handle di atas.
  sheet,

  /// Dialog desktop (Tahap 2): tanpa handle, padding atas 24.
  dialog,
}

/// Overlay Header dari Figma (Components [09], node 49:154): kepala pop-up.
/// Isi dan tombol disusun di bawahnya.
class AppOverlayHeader extends StatelessWidget {
  const AppOverlayHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onClose,
    this.type = AppOverlayHeaderType.sheet,
  });

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _handleWidth = 40;
  static const double _handleHeight = 4;
  static const double _handleRadius = 2;
  static const double _closeSize = 40;
  static const double _closeIconSize = 20;
  static const double _borderWidth = 1;

  final String title;

  /// Keterangan singkat di bawah judul. `null` = disembunyikan.
  final String? subtitle;

  /// Tombol tutup bulat di kanan. `null` = disembunyikan (misalnya
  /// konfirmasi hapus, design-notes §5).
  final VoidCallback? onClose;

  final AppOverlayHeaderType type;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final onClose = this.onClose;
    final isSheet = type == AppOverlayHeaderType.sheet;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.s24,
        isSheet ? AppSpace.s8 : AppSpace.s24,
        AppSpace.s24,
        AppSpace.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpace.s12,
        children: [
          if (isSheet)
            Center(
              child: Container(
                width: _handleWidth,
                height: _handleHeight,
                decoration: BoxDecoration(
                  color: AppColors.darkGray,
                  borderRadius: BorderRadius.circular(_handleRadius),
                ),
              ),
            ),
          Row(
            spacing: AppSpace.s16,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpace.s4,
                  children: [
                    Text(
                      title,
                      style: AppText.headingSmall.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: AppText.bodySmall.copyWith(
                          color: AppColors.gray,
                        ),
                      ),
                  ],
                ),
              ),
              if (onClose != null)
                Semantics(
                  button: true,
                  label: 'Tutup',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onClose,
                    child: Container(
                      width: _closeSize,
                      height: _closeSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.darkGray,
                          width: _borderWidth,
                        ),
                      ),
                      child: const AppIcon(
                        AppIcons.close,
                        size: _closeIconSize,
                        color: AppColors.lightGray,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
