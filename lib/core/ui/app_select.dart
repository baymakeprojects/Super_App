import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_icon.dart';
import 'package:super_app/core/ui/app_label_text.dart';

/// Select dari Figma (Components [07], node 21:65): field pilihan (mata
/// kuliah, dompet, tanggal, jam). Diketuk membuka bottom sheet pilihan,
/// bukan dropdown Material.
class AppSelect extends StatelessWidget {
  const AppSelect({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.placeholder,
    this.icon = AppIcons.chevronDown,
  });

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _iconSize = 20;
  static const double _borderWidth = 1;

  /// Label kecil di atas field. Dikapitalkan otomatis.
  final String label;

  /// Nilai terpilih. `null` = belum dipilih, tampil [placeholder] abu.
  final String? value;

  /// Teks abu saat belum ada nilai (Figma belum punya keadaan ini, F-16).
  final String? placeholder;

  /// Ikon di kanan: bawaan Chevron Down; Calendar atau Clock untuk tanggal
  /// dan jam.
  final AppIcons icon;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final value = this.value;

    return Semantics(
      button: true,
      label: label,
      value: value,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpace.s8,
          children: [
            AppLabelText(
              label,
              style: AppText.labelMedium.copyWith(color: AppColors.lightGray),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpace.s16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                border: Border.all(
                  color: AppColors.darkGray,
                  width: _borderWidth,
                ),
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
              child: Row(
                spacing: AppSpace.s12,
                children: [
                  Expanded(
                    child: Text(
                      value ?? placeholder ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyLarge.copyWith(
                        color: value == null ? AppColors.gray : AppColors.white,
                      ),
                    ),
                  ),
                  AppIcon(icon, size: _iconSize, color: AppColors.gray),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
