import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_badge.dart';
import 'package:super_app/core/ui/app_label_text.dart';

/// Status Bill Item di Figma.
enum AppBillStatus {
  /// Belum jatuh tempo: badge kuning ("4 hari lagi").
  upcoming,

  /// Sudah dibayar: teks abu, badge hijau "Lunas".
  paid,

  /// Lewat jatuh tempo: garis merah, badge merah "Terlambat".
  overdue,
}

/// Bill Item dari Figma (Components [06], node 28:106): tanggal jatuh tempo,
/// nama, "periode · dompet", nominal, dan badge status.
///
/// Dipakai di MVP hanya sebagai ilustrasi 00c Intro 3 (tagihan modul
/// Tahap 2).
class AppBillItem extends StatelessWidget {
  const AppBillItem({
    super.key,
    required this.day,
    required this.month,
    required this.title,
    required this.meta,
    required this.amount,
    required this.status,
    required this.badgeLabel,
  });

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _dueSize = 48;
  static const double _borderWidth = 1;

  /// Tanggal jatuh tempo, misalnya "10".
  final String day;

  /// Bulan singkat, misalnya "Nov". Dikapitalkan otomatis.
  final String month;

  final String title;

  /// "Bulanan · Bank".
  final String meta;

  /// "Rp800.000".
  final String amount;

  final AppBillStatus status;

  /// Teks badge: "4 hari lagi", "Lunas", "Terlambat".
  final String badgeLabel;

  @override
  Widget build(BuildContext context) {
    final paid = status == AppBillStatus.paid;
    final strong = paid ? AppColors.gray : AppColors.white;
    final badgeType = switch (status) {
      AppBillStatus.upcoming => AppBadgeType.warning,
      AppBillStatus.paid => AppBadgeType.success,
      AppBillStatus.overdue => AppBadgeType.danger,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpace.s16),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border.all(
          color: status == AppBillStatus.overdue
              ? AppColors.danger
              : AppColors.darkGray,
          width: _borderWidth,
        ),
        borderRadius: BorderRadius.circular(AppRadius.item),
      ),
      child: Row(
        spacing: AppSpace.s12,
        children: [
          Container(
            width: _dueSize,
            height: _dueSize,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(day, style: AppText.titleMedium.copyWith(color: strong)),
                AppLabelText(
                  month,
                  style: AppText.labelSmall.copyWith(color: AppColors.gray),
                ),
              ],
            ),
          ),
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
                  style: AppText.titleMedium.copyWith(
                    color: paid ? AppColors.lightGray : AppColors.white,
                  ),
                ),
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodySmall.copyWith(color: AppColors.gray),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpace.s4,
            children: [
              Text(amount, style: AppText.titleMedium.copyWith(color: strong)),
              AppBadge(label: badgeLabel, type: badgeType),
            ],
          ),
        ],
      ),
    );
  }
}
