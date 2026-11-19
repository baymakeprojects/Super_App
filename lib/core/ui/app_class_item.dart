import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_badge.dart';
import 'package:super_app/core/ui/app_label_text.dart';

/// Keadaan Class Item di Figma, ditentukan dari jam sekarang.
enum AppClassItemState { upcoming, now, done }

/// Class Item dari Figma (Components [06], node 9:69): kolom jam di kiri,
/// kartu mata kuliah di kanan. Now: garis oranye + badge
/// "Sedang berlangsung". Done: semua teks abu.
class AppClassItem extends StatelessWidget {
  const AppClassItem({
    super.key,
    required this.start,
    required this.end,
    required this.course,
    required this.meta,
    required this.state,
    this.onTap,
  });

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _timeColumnWidth = 52;
  static const double _borderWidth = 1;

  /// Teks badge keadaan Now, disalin dari Figma.
  static const String nowLabel = 'Sedang berlangsung';

  /// Jam mulai, misalnya "08.00".
  final String start;

  /// Jam selesai, misalnya "09.40".
  final String end;

  final String course;

  /// Baris kecil, misalnya "Ruang 301 · Bu Rina".
  final String meta;

  final AppClassItemState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final done = state == AppClassItemState.done;
    final now = state == AppClassItemState.now;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpace.s12,
        children: [
          SizedBox(
            width: _timeColumnWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpace.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpace.s4,
                children: [
                  Text(
                    start,
                    maxLines: 1,
                    style: AppText.titleMedium.copyWith(
                      color: done ? AppColors.gray : AppColors.white,
                    ),
                  ),
                  AppLabelText(
                    end,
                    style: AppText.labelSmall.copyWith(color: AppColors.gray),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppSpace.s16),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                border: Border.all(
                  color: now ? AppColors.brandingOrange : AppColors.darkGray,
                  width: _borderWidth,
                ),
                borderRadius: BorderRadius.circular(AppRadius.item),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpace.s4,
                children: [
                  Text(
                    course,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.titleMedium.copyWith(
                      color: done ? AppColors.gray : AppColors.white,
                    ),
                  ),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodySmall.copyWith(
                      color: done ? AppColors.gray : AppColors.lightGray,
                    ),
                  ),
                  if (now)
                    const AppBadge(label: nowLabel, type: AppBadgeType.success),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
