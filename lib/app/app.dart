import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'package:super_app/app/router.dart';
import 'package:super_app/core/theme/theme.dart';

/// Akar aplikasi Super App: tema gelap dari token dan router dari
/// `docs/navigasi.md`.
class SuperApp extends ConsumerWidget {
  const SuperApp({super.key});

  /// Ikon status bar dan bar navigasi sistem terang di atas latar hitam
  /// (design-notes §2: status bar bukan widget, cukup diatur warnanya).
  static const SystemUiOverlayStyle _systemBars = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.primary,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Super App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: _systemBars,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
