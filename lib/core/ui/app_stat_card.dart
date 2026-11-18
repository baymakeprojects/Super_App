import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_label_text.dart';

/// Stat Card dari Figma (Components [04], node 7:17): ringkasan angka di
/// Beranda. Angka memakai Doto. Dua kartu per baris di HP, jadi lebarnya
/// mengikuti induk (misalnya `Expanded` di dalam `Row`).
class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.caption,
  });

  static const double _borderWidth = 1;

  /// Label kecil abu di atas angka. Dikapitalkan otomatis.
  final String label;

  /// Angka utama, sudah diformat (misalnya "5" atau "Rp1,25jt").
  final String value;

  /// Keterangan di bawah angka.
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.s16),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border.all(color: AppColors.darkGray, width: _borderWidth),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpace.s8,
        children: [
          AppLabelText(
            label,
            style: AppText.labelSmall.copyWith(color: AppColors.gray),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.displaySmall.copyWith(color: AppColors.white),
          ),
          Text(
            caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.bodySmall.copyWith(color: AppColors.lightGray),
          ),
        ],
      ),
    );
  }
}
