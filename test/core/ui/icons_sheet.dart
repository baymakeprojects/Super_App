import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/ui.dart';

/// Peraga bagian [01] Ikon di halaman Components (Figma node 5:7, 1152×780)
/// untuk golden test. Hanya ada di `test/`; kotak peraga tidak dibangun di app.
class IconsSheet extends StatelessWidget {
  const IconsSheet({super.key});

  /// Ukuran frame [01] Ikon di Figma.
  static const Size frameSize = Size(1152, 780);

  /// Jumlah ikon dari portofolio (urutan pertama di [AppIcons]).
  static const int portfolioCount = 13;

  @override
  Widget build(BuildContext context) {
    final portfolio = AppIcons.values.take(portfolioCount);
    final app = AppIcons.values.skip(portfolioCount);

    return ColoredBox(
      color: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.s24,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpace.s8,
            children: [
              Text(
                '[01] Ikon'.toUpperCase(),
                style: AppText.labelMedium.copyWith(
                  color: AppColors.accentText,
                ),
              ),
              SizedBox(
                width: _Spec.descWidth,
                child: Text(
                  'Ikon garis 24px, stroke 1.5, ujung kotak. 13 ikon diambil '
                  'dari portofolio, 22 ikon baru untuk modul app dengan gaya '
                  'yang sama. Ubah ukuran instance, garisnya ikut '
                  'menyesuaikan.',
                  style: AppText.bodyMedium.copyWith(
                    color: AppColors.lightGray,
                  ),
                ),
              ),
            ],
          ),
          const _SubLabel('Dari portofolio'),
          _IconGrid(portfolio),
          const _SubLabel('Baru untuk app'),
          _IconGrid(app),
        ],
      ),
    );
  }
}

/// Ukuran kotak peraga di Figma (bukan token app).
abstract final class _Spec {
  static const double descWidth = 760;
  static const double cellWidth = 130;
  static const double cellRadius = 12;
  static const double cellTop = 20;
}

/// Nama sel di Figma, mis. `arrowUpRight` → "Arrow Up Right".
String _figmaName(AppIcons icon) => icon.fileName
    .split('_')
    .map((word) => word[0].toUpperCase() + word.substring(1))
    .join(' ');

class _SubLabel extends StatelessWidget {
  const _SubLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppText.labelSmall.copyWith(color: AppColors.gray),
    );
  }
}

class _IconGrid extends StatelessWidget {
  const _IconGrid(this.icons);

  final Iterable<AppIcons> icons;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpace.s16,
      runSpacing: AppSpace.s16,
      children: [for (final icon in icons) _IconCell(icon)],
    );
  }
}

class _IconCell extends StatelessWidget {
  const _IconCell(this.icon);

  final AppIcons icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _Spec.cellWidth,
      padding: const EdgeInsets.fromLTRB(
        AppSpace.s8,
        _Spec.cellTop,
        AppSpace.s8,
        AppSpace.s16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border.all(color: AppColors.darkGray),
        borderRadius: BorderRadius.circular(_Spec.cellRadius),
      ),
      child: Column(
        spacing: AppSpace.s12,
        children: [
          AppIcon(icon),
          Text(
            _figmaName(icon).toUpperCase(),
            style: AppText.labelSmall.copyWith(color: AppColors.gray),
          ),
        ],
      ),
    );
  }
}
