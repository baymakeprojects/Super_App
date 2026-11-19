import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_icon.dart';
import 'package:super_app/core/ui/app_label_text.dart';

/// Snackbar dari Figma (Components [11], node 65:187): konfirmasi singkat
/// setelah aksi (hapus, simpan, tandai selesai) dengan aksi Urungkan.
///
/// Satu-satunya komponen yang memakai bayangan, karena Figma memakainya.
class AppSnackbar extends StatelessWidget {
  const AppSnackbar({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon = AppIcons.check,
  });

  // Ukuran tetap dari Figma (bukan variabel Figma).
  static const double _iconSize = 20;
  static const double _borderWidth = 1;
  static const double _shadowOpacity = 0.5;
  static const Offset _shadowOffset = Offset(0, 8);
  static const double _shadowBlur = 12;

  final String message;

  /// Teks aksi, misalnya "Urungkan". `null` = tanpa aksi.
  final String? actionLabel;

  final VoidCallback? onAction;

  /// Ikon hijau di kiri. `null` = tanpa ikon.
  final AppIcons? icon;

  @override
  Widget build(BuildContext context) {
    final actionLabel = this.actionLabel;
    final icon = this.icon;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s16,
        vertical: AppSpace.s12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        border: Border.all(color: AppColors.darkGray, width: _borderWidth),
        borderRadius: BorderRadius.circular(AppRadius.item),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: _shadowOpacity),
            offset: _shadowOffset,
            blurRadius: _shadowBlur,
          ),
        ],
      ),
      child: Row(
        spacing: AppSpace.s12,
        children: [
          if (icon != null)
            AppIcon(icon, size: _iconSize, color: AppColors.success),
          Expanded(
            child: Text(
              message,
              style: AppText.bodyMedium.copyWith(color: AppColors.white),
            ),
          ),
          if (actionLabel != null)
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onAction,
                child: AppLabelText(
                  actionLabel,
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

/// Lama Snackbar tampil (catatan Figma).
const Duration appSnackbarDuration = Duration(seconds: 4);

/// Menampilkan [AppSnackbar] selama 4 detik di atas Bottom Nav (atau di
/// bawah layar kalau tidak ada Bottom Nav). Snackbar sebelumnya ditutup.
void showAppSnackbar(
  BuildContext context, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: AppSnackbar(
        message: message,
        actionLabel: actionLabel,
        onAction: () {
          messenger.hideCurrentSnackBar();
          onAction?.call();
        },
      ),
      duration: appSnackbarDuration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.fromLTRB(
        AppSpace.s20,
        0,
        AppSpace.s20,
        AppSpace.s16,
      ),
    ),
  );
}
