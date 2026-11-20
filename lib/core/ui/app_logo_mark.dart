import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';
import 'package:super_app/core/ui/app_label_text.dart';

/// Ukuran logo "S" di Figma.
enum AppLogoMarkSize {
  /// 28×28, sudut 8, huruf Label/Large (00a–00d, node 63:2011).
  small,

  /// 56×56, sudut 16, huruf Geist Mono SemiBold 26/36 (H06, node 56:2607).
  large,

  /// 96×96: logo kecil diperbesar 3,43× di tengah ilustrasi 00a Intro 1
  /// (node 63:1739). Sudut 27,43, huruf 44,57/61,71.
  hero,
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

  /// Skala 00a: logo 28 diperbesar jadi 96 (Figma menskalakan instance).
  static const double _heroScale = 96 / _smallSide;

  /// Huruf logo 00a: Label/Large ikut diskalakan [_heroScale] (F-59).
  static final TextStyle _heroLetter = AppText.labelLarge.copyWith(
    fontSize: 13 * _heroScale,
    letterSpacing: 1 * _heroScale,
  );

  final AppLogoMarkSize size;

  @override
  Widget build(BuildContext context) {
    final (side, radius, style) = switch (size) {
      AppLogoMarkSize.small => (_smallSide, _smallRadius, AppText.labelLarge),
      AppLogoMarkSize.large => (_largeSide, AppRadius.item, _largeLetter),
      AppLogoMarkSize.hero => (
        _smallSide * _heroScale,
        _smallRadius * _heroScale,
        _heroLetter,
      ),
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
