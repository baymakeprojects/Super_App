import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';

/// Memudarkan [child] masuk setiap kali [trigger] berubah (pindah tab), dan
/// sekali saat pertama tampil kalau [animateFirst] (splash ke layar
/// pertama). Isi [child] tidak dibangun ulang, jadi posisi gulir dan isian
/// tetap.
///
/// Mati kalau pengguna mematikan animasi di pengaturan HP.
class AppFadeIn extends StatefulWidget {
  const AppFadeIn({
    super.key,
    required this.duration,
    required this.child,
    this.trigger,
    this.animateFirst = false,
  });

  final Duration duration;

  /// Nilai yang memicu pudar ulang saat berubah, misalnya indeks tab.
  final Object? trigger;

  final bool animateFirst;
  final Widget child;

  @override
  State<AppFadeIn> createState() => _AppFadeInState();
}

class _AppFadeInState extends State<AppFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.animateFirst ? 0 : 1,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.curve,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.value == 0 && !_controller.isAnimating) _play();
  }

  @override
  void didUpdateWidget(AppFadeIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
      _controller.value = 0;
      _play();
    }
  }

  void _play() {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
      return;
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}
