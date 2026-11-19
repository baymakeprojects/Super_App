import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_button.dart';

/// Action Bar dari Figma (Components [07], node 21:123): bar aksi yang
/// menempel di bawah form dan detail.
///
/// - Single: satu tombol Primary selebar bar.
/// - Double (kalau [secondaryLabel] diisi): kiri Ghost, kanan Primary,
///   lebar sama.
///
/// Seperti Bottom Nav, tinggi gesture bar sistem ditambahkan di bawah.
class AppActionBar extends StatelessWidget {
  const AppActionBar({
    super.key,
    required this.primaryLabel,
    required this.onPrimaryPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
  });

  static const double _borderWidth = 1;

  final String primaryLabel;
  final VoidCallback? onPrimaryPressed;

  /// Tombol Ghost di kiri. `null` = Action Bar Single.
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    final secondaryLabel = this.secondaryLabel;
    final systemBottom = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpace.s20,
        AppSpace.s16,
        AppSpace.s20,
        AppSpace.s20 + systemBottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        border: Border(
          top: BorderSide(color: AppColors.darkGray, width: _borderWidth),
        ),
      ),
      child: Row(
        spacing: AppSpace.s12,
        children: [
          if (secondaryLabel != null)
            Expanded(
              child: AppButton(
                label: secondaryLabel,
                style: AppButtonStyle.ghost,
                onPressed: onSecondaryPressed,
              ),
            ),
          Expanded(
            child: AppButton(label: primaryLabel, onPressed: onPrimaryPressed),
          ),
        ],
      ),
    );
  }
}
