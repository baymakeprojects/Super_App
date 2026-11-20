import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_badge.dart';
import 'package:super_app/core/ui/app_icon.dart';

/// Keadaan Module Tile (properti `State` di Figma, set 257:252).
enum AppModuleTileState {
  /// Modul sudah ada: ikon oranye, judul putih, caption, bisa diketuk.
  normal,

  /// Modul belum dibuat (MVP): ikon dan judul Gray, Badge "Segera",
  /// tidak bisa diketuk (F-66).
  segera,
}

/// Module Tile dari Figma (Components, set 257:252: State=Default 9:87,
/// State=Segera 257:243). Pintasan modul di layar Lainnya, dua kolom di HP.
/// Lebar mengikuti induk; tinggi mengikuti isi.
class AppModuleTile extends StatelessWidget {
  const AppModuleTile({
    super.key,
    required this.icon,
    required this.title,
    this.caption,
    this.state = AppModuleTileState.normal,
    this.onTap,
  });

  /// Label Badge pada keadaan Segera (Figma 257:243).
  static const String segeraLabel = 'Segera';

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _iconBoxSize = 40;
  static const double _borderWidth = 1;

  final AppIcons icon;
  final String title;

  /// Baris kecil di bawah judul. Hanya tampil pada keadaan normal.
  final String? caption;

  final AppModuleTileState state;

  /// Diabaikan pada keadaan Segera.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isSegera = state == AppModuleTileState.segera;
    final caption = this.caption;

    final tile = Container(
      padding: const EdgeInsets.all(AppSpace.s16),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border.all(color: AppColors.darkGray, width: _borderWidth),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpace.s12,
        children: [
          Container(
            width: _iconBoxSize,
            height: _iconBoxSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: AppIcon(
              icon,
              color: isSegera ? AppColors.gray : AppColors.brandingOrange,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.s4,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.titleMedium.copyWith(
                  color: isSegera ? AppColors.gray : AppColors.white,
                ),
              ),
              if (isSegera)
                const AppBadge(label: segeraLabel)
              else if (caption != null)
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodySmall.copyWith(color: AppColors.gray),
                ),
            ],
          ),
        ],
      ),
    );

    final onTap = this.onTap;
    if (isSegera || onTap == null) {
      return Semantics(
        container: true,
        label: isSegera ? '$title, segera' : null,
        excludeSemantics: isSegera,
        child: tile,
      );
    }
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: tile,
      ),
    );
  }
}
