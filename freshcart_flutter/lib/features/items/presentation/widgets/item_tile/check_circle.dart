import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';

/// The row's checkmark: a plain filled/outlined circle rather than
/// [Checkbox], whose Material fill colour, size, and checkmark weight don't
/// match the design's spec (same reasoning as `QuantityStepper`'s
/// hand-painted glyphs).
class CheckCircle extends StatelessWidget {
  const CheckCircle({
    required this.value,
    required this.onChanged,
    required this.fillProgress,
    super.key,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final Animation<double> fillProgress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onChanged(!value),
      customBorder: const CircleBorder(),
      child: AnimatedBuilder(
        animation: fillProgress,
        builder: (context, child) {
          // 340ms easeOutBack overshoot on checking; a plain, un-curved
          // reverse on unchecking -- same asymmetry item_tile.dart's own
          // _checkFill uses, so checking reads as an action, not a flip.
          final eased = fillProgress.status == AnimationStatus.reverse
              ? fillProgress.value
              : Curves.easeOutBack.transform(fillProgress.value);
          final clamped = eased.clamp(0.0, 1.0);
          return Container(
            width: AppSizes.checkCircle,
            height: AppSizes.checkCircle,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // `onSurface`/`surface`, not the fixed `AppColors.bgDark`/
              // `bgLight` this used to read -- those are light-mode-only
              // literals (the seed swatches `AppTheme` builds *from*), so a
              // "checked" circle painted with them stayed near-black in dark
              // mode too and all but disappeared against a dark row. The
              // scheme roles invert with brightness the way the design's own
              // ink-on-paper checkbox is supposed to.
              color: Color.lerp(Colors.transparent, scheme.onSurface, clamped),
              border: value
                  ? null
                  : Border.all(color: scheme.outline, width: 1.5),
            ),
            child: clamped <= 0
                ? null
                : Padding(
                    padding: const EdgeInsets.all(6),
                    child: Opacity(
                      opacity: clamped,
                      child: Transform.scale(
                        scale: eased,
                        child: CustomPaint(
                          painter: _CheckGlyphPainter(color: scheme.surface),
                        ),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _CheckGlyphPainter extends CustomPainter {
  const _CheckGlyphPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(0, size.height * 0.55)
      ..lineTo(size.width * 0.38, size.height)
      ..lineTo(size.width, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckGlyphPainter old) => old.color != color;
}
