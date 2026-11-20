import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_label_text.dart';
import 'package:super_app/core/ui/app_progress_bar.dart';

/// Status Budget Item di Figma.
enum AppBudgetStatus {
  /// Di bawah 80%: bar oranye.
  normal,

  /// 80% atau lebih: bar kuning.
  warning,

  /// Lebih dari 100%: bar dan keterangan merah.
  over,
}

/// Budget Item dari Figma (Components [06], node 28:130): nama kategori,
/// "terpakai / batas", Progress Bar, dan keterangan sisa.
///
/// Dipakai di MVP hanya sebagai ilustrasi 00c Intro 3 (budget modul
/// Tahap 2).
class AppBudgetItem extends StatelessWidget {
  const AppBudgetItem({
    super.key,
    required this.title,
    required this.amount,
    required this.caption,
    required this.value,
    required this.status,
  });

  static const double _borderWidth = 1;

  /// "Makan".
  final String title;

  /// "Rp480rb / Rp600rb". Dikapitalkan otomatis.
  final String amount;

  /// "Sisa Rp120rb · 80%".
  final String caption;

  /// Isi bar 0–100.
  final double value;

  final AppBudgetStatus status;

  @override
  Widget build(BuildContext context) {
    final (barColor, captionColor) = switch (status) {
      AppBudgetStatus.normal => (AppColors.brandingOrange, AppColors.gray),
      AppBudgetStatus.warning => (AppColors.warning, AppColors.gray),
      AppBudgetStatus.over => (AppColors.danger, AppColors.danger),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpace.s16),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border.all(color: AppColors.darkGray, width: _borderWidth),
        borderRadius: BorderRadius.circular(AppRadius.item),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpace.s8,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppText.titleMedium.copyWith(color: AppColors.white),
              ),
              AppLabelText(
                amount,
                style: AppText.labelSmall.copyWith(color: AppColors.lightGray),
              ),
            ],
          ),
          AppProgressBar(value: value, color: barColor),
          Text(caption, style: AppText.bodySmall.copyWith(color: captionColor)),
        ],
      ),
    );
  }
}
