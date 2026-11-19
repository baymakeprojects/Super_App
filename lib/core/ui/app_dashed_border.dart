import 'dart:ui' show PathMetric;

import 'package:material_ui/material_ui.dart';

import 'package:super_app/core/theme/theme.dart';

/// Garis putus-putus di sekeliling [child], sudut [radius]. Dipakai kotak
/// kosong E1 "Belum ada tugas" (Figma 67:1970).
class AppDashedBorder extends StatelessWidget {
  const AppDashedBorder({
    super.key,
    required this.child,
    this.color = AppColors.darkGray,
    this.radius = AppRadius.card,
  });

  /// Pola garis: Figma tidak menyebut panjang putus-putus (F-53).
  static const double dash = 4;
  static const double gap = 4;
  static const double strokeWidth = 1;

  final Widget child;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedRRectPainter(color: color, radius: radius),
      child: child,
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = AppDashedBorder.strokeWidth / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        inset,
        inset,
        size.width - inset * 2,
        size.height - inset * 2,
      ),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppDashedBorder.strokeWidth;
    final path = Path()..addRRect(rrect);
    for (final PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + AppDashedBorder.dash),
          paint,
        );
        distance += AppDashedBorder.dash + AppDashedBorder.gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
