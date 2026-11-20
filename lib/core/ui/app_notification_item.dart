import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_icon.dart';
import 'package:super_app/core/ui/app_label_text.dart';

/// Notification Item dari Figma (Components [06], node 21:144): pengingat
/// kelas, deadline, tagihan, sinkron. Unread: ikon oranye dan titik oranye
/// di kanan; Read: judul dan isi lebih redup.
///
/// Dipakai di MVP hanya sebagai ilustrasi 00b Intro 2 (pusat notifikasi
/// sendiri modul Tahap 2).
class AppNotificationItem extends StatelessWidget {
  const AppNotificationItem({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    this.unread = true,
    this.iconColor,
    this.showDivider = true,
  });

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _leadingSize = 40;
  static const double _iconSize = 20;
  static const double _dotSize = 8;
  static const double _borderWidth = 1;

  final AppIcons icon;
  final String title;

  /// "Pemrograman Mobile · Ruang 301".
  final String body;

  /// "07.35".
  final String time;

  final bool unread;

  /// Warna ikon kalau instance Figma mengubahnya (00b: putih). `null` =
  /// bawaan komponen (Unread oranye, Read abu).
  final Color? iconColor;

  /// Garis bawah Dark Gray antarbaris. Mati kalau item dibungkus kartu.
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.s16),
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.darkGray,
                  width: _borderWidth,
                ),
              ),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.s12,
        children: [
          Container(
            width: _leadingSize,
            height: _leadingSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(AppRadius.input),
            ),
            child: AppIcon(
              icon,
              size: _iconSize,
              color:
                  iconColor ??
                  (unread ? AppColors.brandingOrange : AppColors.lightGray),
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
                  style: AppText.titleMedium.copyWith(
                    color: unread ? AppColors.white : AppColors.lightGray,
                  ),
                ),
                Text(
                  body,
                  style: AppText.bodyMedium.copyWith(
                    color: unread ? AppColors.lightGray : AppColors.gray,
                  ),
                ),
                AppLabelText(
                  time,
                  style: AppText.labelSmall.copyWith(color: AppColors.gray),
                ),
              ],
            ),
          ),
          if (unread)
            Container(
              width: _dotSize,
              height: _dotSize,
              decoration: const BoxDecoration(
                color: AppColors.brandingOrange,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
