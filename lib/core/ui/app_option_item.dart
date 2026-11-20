import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_icon.dart';
import 'package:super_app/core/ui/app_label_text.dart';

/// Option Item dari Figma (Components [09], node 49:174): baris pilihan di
/// pop-up (mata kuliah, dompet, periode). Satu pilihan aktif = Selected:
/// latar Surface/Card, garis oranye, radio terisi.
class AppOptionItem extends StatelessWidget {
  const AppOptionItem({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.caption,
    this.value,
    this.icon,
  });

  static const double _borderWidth = 1;

  final String title;

  /// Keterangan abu di bawah judul. `null` = disembunyikan.
  final String? caption;

  /// Nilai kapital di kanan, misalnya saldo. `null` = disembunyikan.
  final String? value;

  /// Ikon di kiri. `null` = disembunyikan.
  final AppIcons? icon;

  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final caption = this.caption;
    final value = this.value;
    final icon = this.icon;

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.s16,
            vertical: AppSpace.s12,
          ),
          // Default juga bergaris 1px (transparan), jadi tinggi Default dan
          // Selected sama dan daftar tidak bergeser (F-18, diubah di Figma
          // 20 Nov 2026).
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceCard : null,
            border: Border.all(
              color: selected ? AppColors.brandingOrange : Colors.transparent,
              width: _borderWidth,
            ),
            borderRadius: BorderRadius.circular(AppRadius.item),
          ),
          child: Row(
            spacing: AppSpace.s12,
            children: [
              if (icon != null) AppIcon(icon),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpace.s4,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyLarge.copyWith(color: AppColors.white),
                    ),
                    if (caption != null)
                      Text(
                        caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodySmall.copyWith(
                          color: AppColors.gray,
                        ),
                      ),
                  ],
                ),
              ),
              if (value != null)
                AppLabelText(
                  value,
                  style: AppText.labelMedium.copyWith(
                    color: AppColors.lightGray,
                  ),
                ),
              _Radio(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

/// Radio 20px: kosong = lingkaran garis abu; terpilih = lingkaran oranye
/// dengan titik hitam.
class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _size = 20;
  static const double _dotSize = 8;
  static const double _borderWidth = 1.5;

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.brandingOrange : null,
        border: selected
            ? null
            : Border.all(color: AppColors.gray, width: _borderWidth),
      ),
      child: selected
          ? Container(
              width: _dotSize,
              height: _dotSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.onAccent,
              ),
            )
          : null,
    );
  }
}
