import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/app_colors.dart';
import 'package:super_app/core/theme/app_motion.dart';
import 'package:super_app/core/theme/app_text.dart';

/// Tema app. Hanya mode gelap; tidak ada tema terang.
///
/// Dibuat seluruhnya dari token Figma supaya tidak ada warna bawaan
/// Material (ungu, bayangan, ripple). Komponen `core/ui` tetap memakai
/// token langsung; tema ini hanya cadangan untuk widget dasar.
abstract final class AppTheme {
  static final ThemeData dark = _buildDark();

  static ThemeData _buildDark() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.brandingOrange,
      onPrimary: AppColors.onAccent,
      secondary: AppColors.brandingOrange,
      onSecondary: AppColors.onAccent,
      error: AppColors.danger,
      onError: AppColors.primary,
      surface: AppColors.primary,
      onSurface: AppColors.white,
      onSurfaceVariant: AppColors.gray,
      surfaceContainerLowest: AppColors.primary,
      surfaceContainerLow: AppColors.surfaceRaised,
      surfaceContainer: AppColors.surfaceRaised,
      surfaceContainerHigh: AppColors.surfaceCard,
      surfaceContainerHighest: AppColors.surfaceCard,
      outline: AppColors.darkGray,
      outlineVariant: AppColors.darkGray,
      scrim: AppColors.primary,
      shadow: Colors.transparent,
      surfaceTint: Colors.transparent,
    );

    // Nama gaya Material dipetakan ke nama gaya Figma.
    final textTheme = const TextTheme(
      displayLarge: AppText.displayLarge,
      displayMedium: AppText.displayMedium,
      displaySmall: AppText.displaySmall,
      headlineLarge: AppText.headingLarge,
      headlineMedium: AppText.headingMedium,
      headlineSmall: AppText.headingSmall,
      titleMedium: AppText.titleMedium,
      bodyLarge: AppText.bodyLarge,
      bodyMedium: AppText.bodyMedium,
      bodySmall: AppText.bodySmall,
      labelLarge: AppText.labelLarge,
      labelMedium: AppText.labelMedium,
      labelSmall: AppText.labelSmall,
    ).apply(bodyColor: AppColors.white, displayColor: AppColors.white);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.primary,
      canvasColor: AppColors.primary,
      dividerColor: AppColors.darkGray,
      textTheme: textTheme,
      // Tanpa efek ripple, sorotan, atau warna hover bawaan Material.
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      // Transisi layar geser + pudar yang sama di semua platform.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: AppPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
          TargetPlatform.macOS: AppPageTransitionsBuilder(),
          TargetPlatform.linux: AppPageTransitionsBuilder(),
        },
      ),
    );
  }
}
