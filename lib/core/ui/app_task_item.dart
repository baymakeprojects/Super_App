import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_badge.dart';
import 'package:super_app/core/ui/app_checkbox.dart';

/// Task Item dari Figma (Components [06], node 8:75): Checkbox, judul,
/// meta "Mata kuliah · jam", Badge status di kanan.
/// Done: checkbox oranye, judul dan meta abu.
class AppTaskItem extends StatelessWidget {
  const AppTaskItem({
    super.key,
    required this.title,
    required this.meta,
    required this.done,
    this.badge,
    this.onDoneChanged,
    this.onTap,
  });

  static const double _borderWidth = 1;

  final String title;

  /// Baris kecil di bawah judul, misalnya "Pemrograman Mobile · 23.59".
  final String meta;

  final bool done;

  /// Badge status di kanan (Hari ini, Terlambat, Selesai, …). `null` = tanpa.
  final AppBadge? badge;

  /// Dipanggil saat checkbox diketuk.
  final ValueChanged<bool>? onDoneChanged;

  /// Dipanggil saat baris diketuk (membuka detail).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badge = this.badge;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.s16),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          border: Border.all(color: AppColors.darkGray, width: _borderWidth),
          borderRadius: BorderRadius.circular(AppRadius.item),
        ),
        child: Row(
          spacing: AppSpace.s12,
          children: [
            AppCheckbox(value: done, onChanged: onDoneChanged),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpace.s4,
                children: [
                  Text(
                    title,
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
                    style: AppText.bodySmall.copyWith(color: AppColors.gray),
                  ),
                ],
              ),
            ),
            ?badge,
          ],
        ),
      ),
    );
  }
}
