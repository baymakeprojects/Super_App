import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_label_text.dart';

/// Day Pill dari Figma (Components [06], node 9:79): pemilih hari di jadwal
/// kuliah. Selected = isi oranye, teks hitam.
class AppDayPill extends StatelessWidget {
  const AppDayPill({
    super.key,
    required this.day,
    required this.date,
    required this.selected,
    required this.onTap,
  });

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double width = 52;
  static const double _borderWidth = 1;

  /// Nama hari singkat, misalnya "Jum". Dikapitalkan otomatis.
  final String day;

  /// Tanggal, misalnya "7".
  final String date;

  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandingOrange : null,
            border: Border.all(
              color: selected ? AppColors.brandingOrange : AppColors.darkGray,
              width: _borderWidth,
            ),
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.s4,
            children: [
              AppLabelText(
                day,
                style: AppText.labelSmall.copyWith(
                  color: selected ? AppColors.onAccent : AppColors.gray,
                ),
              ),
              Text(
                date,
                maxLines: 1,
                style: AppText.titleMedium.copyWith(
                  color: selected ? AppColors.onAccent : AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
