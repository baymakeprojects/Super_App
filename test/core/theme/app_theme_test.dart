import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';

void main() {
  group('Token', () {
    test('tinggi baris mengikuti Figma (tinggi ÷ ukuran)', () {
      expect(AppText.displayLarge.fontSize! * AppText.displayLarge.height!, 48);
      expect(AppText.headingLarge.fontSize! * AppText.headingLarge.height!, 34);
      expect(AppText.labelLarge.fontSize! * AppText.labelLarge.height!, 18);
    });

    test('Doto hanya untuk Display, Geist Mono untuk Label', () {
      expect(AppText.displayLarge.fontFamily, AppText.doto);
      expect(AppText.bodyMedium.fontFamily, AppText.geist);
      expect(AppText.labelSmall.fontFamily, AppText.geistMono);
    });

    test('gradien Branding punya 4 titik seperti Figma', () {
      const gradient = AppColors.gradientBranding;
      expect(gradient.colors, [
        AppColors.gradientSand,
        AppColors.gradientFlame,
        AppColors.gradientRed,
        AppColors.primary,
      ]);
      expect(gradient.stops, [0, 0.22, 0.55, 1]);
    });
  });

  group('AppTheme.dark', () {
    final theme = AppTheme.dark;

    test('mode gelap dengan latar Primary', () {
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.primary);
      expect(theme.colorScheme.primary, AppColors.brandingOrange);
      expect(theme.colorScheme.onPrimary, AppColors.onAccent);
    });

    test('gaya teks Material dipetakan ke gaya Figma', () {
      expect(theme.textTheme.displayLarge?.fontFamily, AppText.doto);
      expect(theme.textTheme.headlineLarge?.fontSize, 28);
      expect(theme.textTheme.bodyMedium?.fontFamily, AppText.geist);
      expect(theme.textTheme.bodyMedium?.color, AppColors.white);
      expect(theme.textTheme.labelLarge?.fontFamily, AppText.geistMono);
    });

    test('tanpa ripple Material', () {
      expect(theme.splashFactory, NoSplash.splashFactory);
    });
  });
}
