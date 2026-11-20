import 'package:material_ui/material_ui.dart';

/// Token gerak app. Figma belum punya animasi; nilai ini pengecualian yang
/// disetujui Bayu 21 Nov 2026 (design-notes §9): halus, singkat, dan sama
/// di semua layar.
abstract final class AppMotion {
  /// Layar baru masuk (geser + pudar).
  static const Duration page = Duration(milliseconds: 250);

  /// Pindah tab Bottom Nav (pudar).
  static const Duration tab = Duration(milliseconds: 200);

  /// Splash native ke layar pertama (pudar dari hitam).
  static const Duration launch = Duration(milliseconds: 300);

  static const Curve curve = Curves.easeOutCubic;

  /// Jarak geser layar baru: 6% lebar layar dari kanan.
  static const double pageSlide = 0.06;
}

/// Transisi semua layar penuh (go_router memakai MaterialPage): layar baru
/// bergeser sedikit dari kanan sambil memudar masuk; layar di bawahnya
/// diam.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Duration get transitionDuration => AppMotion.page;

  @override
  Duration get reverseTransitionDuration => AppMotion.page;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: AppMotion.curve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(AppMotion.pageSlide, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
