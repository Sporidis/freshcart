import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';

/// The app's mark: a basket, drawn from the design's own SVG path data
/// rather than a bundled asset, so it can be recoloured (dark on the splash,
/// ink on Welcome) without shipping two image files.
///
/// This is the single source both [SplashScreen] and [WelcomeScreen] draw
/// from — they share it through a `Hero` (see [heroTag]), which is only
/// convincing if both ends are pixel-identical.
class BasketMark extends StatelessWidget {
  /// Creates the mark at [size] logical pixels, stroked in [color].
  const BasketMark({required this.size, required this.color, super.key});

  /// The side length of the mark's square bounding box.
  final double size;

  /// The stroke colour.
  final Color color;

  /// The `Hero` tag shared by every place this mark appears, so navigating
  /// between them animates one mark flying rather than two crossfading.
  static const String heroTag = 'basket-mark';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BasketMarkPainter(color: color)),
    );
  }
}

/// Draws the design's basket glyph: a viewBox-58 path traced 1:1 from the
/// reference markup (`Flow Screens.dc.html`, the Splash frame), scaled to
/// whatever box it is given.
class _BasketMarkPainter extends CustomPainter {
  const _BasketMarkPainter({required this.color});

  final Color color;

  /// The glyph's native viewBox, so every stroke width below is exactly the
  /// design's own — only the canvas transform changes size, not the paths.
  static const double _viewBoxSize = 58;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _viewBoxSize;
    canvas.save();
    canvas.scale(scale);

    // The basket body: a rounded trapezoid, its two bottom corners rounded
    // the way `stroke-linejoin="round"` renders a sharp path corner.
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

    // The two fold lines across the basket's face.
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

@Preview(group: 'Onboarding', name: 'Basket mark', size: Size(200, 100))
Widget basketMarkPreview() => previewPiece(
  const Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 24,
    children: [
      BasketMark(size: 44, color: AppColors.ink),
      BasketMark(size: 24, color: AppColors.ink),
    ],
  ),
);
