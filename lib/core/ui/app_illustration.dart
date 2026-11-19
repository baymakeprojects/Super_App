import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

/// Ilustrasi SVG yang diunduh dari frame Figma (`assets/illustrations/`).
/// Dipakai apa adanya, tidak digambar ulang.
enum AppIllustrations {
  /// Dot Matrix 280×280 di 01 Kunci sidik jari (12:20) dan G1 (137:4105):
  /// titik oranye, cincin sensor, dan ikon sidik jari.
  sensorDotMatrix('sensor_dot_matrix', 280),

  /// Glow 340×340 di 00d Intro 4 (63:2015).
  introGlow('intro_glow', 340),

  /// Cincin progres titik oranye 306×306 di 00d Intro 4 (63:2016).
  introRing('intro_ring', 306),

  /// Ikon sidik jari 56×56 di 00d Intro 4 (63:2066). Garisnya tetap 1,5
  /// (AppIcon akan menebalkan garis saat diperbesar).
  introFingerprint('intro_fingerprint', 56);

  const AppIllustrations(this.fileName, this.size);

  final String fileName;

  /// Sisi ilustrasi (persegi) di Figma.
  final double size;

  String get assetPath => 'assets/illustrations/$fileName.svg';
}

/// Satu ilustrasi Figma dengan ukuran aslinya.
class AppIllustration extends StatelessWidget {
  const AppIllustration(this.illustration, {super.key});

  final AppIllustrations illustration;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      illustration.assetPath,
      width: illustration.size,
      height: illustration.size,
      excludeFromSemantics: true,
    );
  }
}
