import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_label_text.dart';

/// Section Header dari Figma (Components [06], node 8:53): judul di kiri,
/// tautan aksi oranye kapital di kanan (misalnya "Lihat semua →").
/// Tautan disembunyikan kalau [actionLabel] `null`. Lebar mengikuti induk.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onActionPressed,
  });

  final String title;

  /// Teks tautan, disalin dari Figma. Dikapitalkan otomatis.
  final String? actionLabel;

  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final actionLabel = this.actionLabel;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.headingSmall.copyWith(color: AppColors.white),
          ),
        ),
        if (actionLabel != null)
          Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onActionPressed,
              child: AppLabelText(
                actionLabel,
                style: AppText.labelSmall.copyWith(color: AppColors.accentText),
              ),
            ),
          ),
      ],
    );
  }
}
