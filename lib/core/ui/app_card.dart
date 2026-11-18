import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_label_text.dart';

/// Card dari Figma (Components [04], node 7:11): latar Surface/Raised,
/// garis Dark Gray, sudut 20. Lebar mengikuti layar (stretch).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.body,
    this.onTap,
  });

  static const double _borderWidth = 1;

  /// Label kecil oranye di atas judul. Dikapitalkan otomatis.
  final String eyebrow;

  /// Judul kartu, maksimal 2 baris.
  final String title;

  /// Isi singkat, maksimal 2 baris (catatan Figma).
  final String body;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.s20),
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
            eyebrow,
            style: AppText.labelSmall.copyWith(color: AppColors.accentText),
          ),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.headingSmall.copyWith(color: AppColors.white),
          ),
          Text(
            body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppText.bodyMedium.copyWith(color: AppColors.lightGray),
          ),
        ],
      ),
    );

    final onTap = this.onTap;
    if (onTap == null) return card;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}
