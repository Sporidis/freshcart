import 'package:flutter/material.dart';

/// The app logo: a basket, drawn in code (not an image file), so it can be
/// any colour.
///
/// Used by [SplashScreen].
class BasketMark extends StatelessWidget {
  /// Creates the mark at [size] logical pixels, stroked in [color].
  const BasketMark({required this.size, required this.color, super.key});

  /// Width and height of the logo.
  final double size;

  /// The stroke colour.
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BasketMarkPainter(color: color)),
    );
  }
}

/// Draws the basket. Copied from the design's SVG (58 x 58), then scaled
/// to the given size.
class _BasketMarkPainter extends CustomPainter {
  const _BasketMarkPainter({required this.color});

  final Color color;

  /// The SVG's original size. We draw at this size and scale the canvas,
  /// so all numbers below match the SVG exactly.
  static const double _viewBoxSize = 58;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _viewBoxSize;
    canvas.save();
    canvas.scale(scale);

    // The basket: a shape wider at the top, with rounded bottom corners.
    final body = Path()
      ..moveTo(12, 22)
      ..lineTo(46, 22)
      ..lineTo(42, 48)
      ..cubicTo(42, 50.2, 40.2, 51.4, 38, 51.4)
      ..lineTo(20, 51.4)
      ..cubicTo(17.8, 51.4, 16.2, 50.2, 16, 48)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // The handle: one arc from the basket's left rim to its right rim.
    final handle = Path()
      ..moveTo(19, 22)
      ..cubicTo(19, 15, 23.5, 10, 29, 10)
      ..cubicTo(34.5, 10, 39, 15, 39, 22);
    canvas.drawPath(
      handle,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // The two lines across the front of the basket.
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(const Offset(16, 30), const Offset(42, 30), linePaint);
    canvas.drawLine(const Offset(17.3, 38), const Offset(40.7, 38), linePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BasketMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
