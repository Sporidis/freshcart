import 'package:flutter/material.dart';

/// The cart's undercarriage: handle, legs and wheels.
///
/// Painted *behind* the grocery items — nothing here ever needs to occlude
/// them, since it sits below/around the basket, not in front of it. Pair
/// with [CartFrontPainter].
class CartBackPainter extends CustomPainter {
  const CartBackPainter({required this.color, required this.wheelRotation});

  final Color color;

  /// Radians; kept in sync with how far the cart has rolled so the wheels
  /// spin as it moves instead of sliding in place.
  final double wheelRotation;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Push handle: a short post with a horizontal bar at the back.
    const postTop = Offset(18, 4);
    canvas.drawLine(CartShape.backTop, postTop, paint);
    canvas.drawLine(postTop, Offset(postTop.dx + 38, postTop.dy), paint);

    // Front leg + wheel.
    canvas.drawLine(CartShape.frontBottom, CartShape.frontAxle, paint);
    _drawWheel(canvas, paint, CartShape.frontAxle, 13);

    // Back leg + wheel.
    canvas.drawLine(CartShape.backBottom, CartShape.backAxle, paint);
    _drawWheel(canvas, paint, CartShape.backAxle, 13);
  }

  void _drawWheel(Canvas canvas, Paint paint, Offset center, double radius) {
    canvas.drawCircle(center, radius, paint);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(wheelRotation);
    final spoke = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-radius + 3, 0), Offset(radius - 3, 0), spoke);
    canvas.drawLine(Offset(0, -radius + 3), Offset(0, radius - 3), spoke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CartBackPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.wheelRotation != wheelRotation;
}

/// The cart's basket: an opaque body, wire mesh, and its outline.
///
/// Painted *in front of* the grocery items and filled with [fillColor] (the
/// screen's background) so the basket reads as solid — items sitting behind
/// it are hidden below the rim, not floating in front of the cart. Pair with
/// [CartBackPainter].
class CartFrontPainter extends CustomPainter {
  const CartFrontPainter({required this.color, required this.fillColor});

  final Color color;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Path()
      ..moveTo(CartShape.backTop.dx, CartShape.backTop.dy)
      ..lineTo(CartShape.frontTop.dx, CartShape.frontTop.dy)
      ..lineTo(CartShape.frontBottom.dx, CartShape.frontBottom.dy)
      ..lineTo(CartShape.backBottom.dx, CartShape.backBottom.dy)
      ..close();

    // Opaque fill first, so items behind the rim are hidden, not floating
    // in front of the basket.
    canvas.drawPath(body, Paint()..color = fillColor);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(body, paint);

    // Wire mesh, drawn on top of the fill.
    paint.strokeWidth = 2.5;
    for (final t in [0.33, 0.66]) {
      final top = Offset.lerp(CartShape.backTop, CartShape.frontTop, t)!;
      final bottom = Offset.lerp(
        CartShape.backBottom,
        CartShape.frontBottom,
        t,
      )!;
      canvas.drawLine(top, bottom, paint);
    }
    final midLeft = Offset.lerp(CartShape.backTop, CartShape.backBottom, 0.5)!;
    final midRight = Offset.lerp(
      CartShape.frontTop,
      CartShape.frontBottom,
      0.5,
    )!;
    canvas.drawLine(midLeft, midRight, paint);
  }

  @override
  bool shouldRepaint(covariant CartFrontPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.fillColor != fillColor;
}

/// Shared basket coordinates for [CartBackPainter] and [CartFrontPainter], so
/// the two layers always line up.
abstract final class CartShape {
  // Tilted like a side-view cart: wider/higher at the back-left, narrower/
  // lower at the front-right.
  static const backTop = Offset(30, 30);
  static const frontTop = Offset(175, 18);
  static const frontBottom = Offset(163, 78);
  static const backBottom = Offset(45, 88);

  static const frontAxle = Offset(158, 118);
  static const backAxle = Offset(62, 118);
}
