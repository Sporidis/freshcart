import 'package:flutter/material.dart';

/// A dashed rounded-rectangle outline -- Flutter has no built-in dashed
/// [Border], and a small hand-rolled painter beats pulling in a dependency
/// for one outline.
///
/// The design uses the dash for exactly one meaning, "add another": the shop
/// strip's permanent "+" pill and onboarding's "Add a shop not listed" row.
/// One painter for both keeps that meaning looking identical in both places.
class DashedOutlinePainter extends CustomPainter {
  /// Paints a dashed outline in [color]. A null [radius] draws a stadium
  /// (fully rounded ends, `height / 2`) -- the pill shape.
  const DashedOutlinePainter({required this.color, this.radius});

  final Color color;

  /// Corner radius, or null for a stadium.
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
