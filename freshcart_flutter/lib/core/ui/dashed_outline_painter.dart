import 'package:flutter/material.dart';

/// Draws a dashed border with rounded corners.
///
/// Flutter has no dashed [Border], and this is too small to need a package.
/// In the design, a dashed border always means "add something".
class DashedOutlinePainter extends CustomPainter {
  /// Draws a dashed border in [color]. If [radius] is null, the ends are
  /// fully round (a pill shape).
  const DashedOutlinePainter({required this.color, this.radius});

  final Color color;

  /// Corner radius, or null for a pill shape.
  final double? radius;

  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius ?? size.height / 2),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + _dash),
          paint,
        );
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedOutlinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
