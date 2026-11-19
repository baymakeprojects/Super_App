import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_button.dart';
import 'package:super_app/core/ui/app_icon.dart';
import 'package:super_app/core/ui/app_label_text.dart';

/// Pola keadaan kosong E2, E3, K1 (design-notes §6): ikon oranye dalam
/// lingkaran, judul "Belum ada …", satu kalimat, satu tombol.
/// Acuan ukuran: frame E2 Tugas kosong (67:2018).
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.linkLabel,
    this.onLink,
  });

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _circleSize = 72;
  static const double _iconSize = 28;
  static const double _messageWidth = 300;
  static const double _borderWidth = 1;

  final AppIcons icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

  /// Tautan teks oranye di bawah tombol, misalnya "Atau isi lewat setup
  /// awal" di K1. `null` = disembunyikan.
  final String? linkLabel;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final linkLabel = this.linkLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s24,
        vertical: AppSpace.s32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpace.s16,
        children: [
          Container(
            width: _circleSize,
            height: _circleSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.darkGray,
                width: _borderWidth,
              ),
            ),
            child: AppIcon(
              icon,
              size: _iconSize,
              color: AppColors.brandingOrange,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.headingMedium.copyWith(color: AppColors.white),
          ),
          SizedBox(
            width: _messageWidth,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.bodyMedium.copyWith(color: AppColors.gray),
            ),
          ),
          AppButton(label: actionLabel, expand: false, onPressed: onAction),
          if (linkLabel != null)
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onLink,
                child: AppLabelText(
                  linkLabel,
                  style: AppText.labelMedium.copyWith(
                    color: AppColors.accentText,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
