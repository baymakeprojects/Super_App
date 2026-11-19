import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_label_text.dart';

/// Ukuran logo "S" di Figma.
enum AppLogoMarkSize {
  /// 28×28, sudut 8, huruf Label/Large (00a–00d, node 63:2011).
  small,

  /// 56×56, sudut 16, huruf Geist Mono SemiBold 26/36 (H06, node 56:2607).
  large,
}

/// Logo "S" putih-hitam di kotak oranye.
class AppLogoMark extends StatelessWidget {
  const AppLogoMark({super.key, this.size = AppLogoMarkSize.small});

  // Ukuran tetap dari Figma (bukan variabel Figma, F-48).
  static const double _smallSide = 28;
  static const double _smallRadius = 8;
  static const double _largeSide = 56;

  /// Huruf logo besar: tidak ada gaya teks Figma untuk ukuran ini (F-48).
  static final TextStyle _largeLetter = AppText.labelLarge.copyWith(
    fontSize: 26,
    height: 36 / 26,
    letterSpacing: 2,
  );

  final AppLogoMarkSize size;

  @override
  Widget build(BuildContext context) {
    final (side, radius, style) = switch (size) {
      AppLogoMarkSize.small => (_smallSide, _smallRadius, AppText.labelLarge),
      AppLogoMarkSize.large => (_largeSide, AppRadius.item, _largeLetter),
    };
    return Container(
      width: side,
      height: side,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.brandingOrange,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: AppLabelText(
        'S',
        style: style.copyWith(color: AppColors.onAccent),
      ),
    );
  }
}
