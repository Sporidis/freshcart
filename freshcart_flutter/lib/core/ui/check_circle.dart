import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';

/// The round checkbox from the design (v3): a neutral 2px ring, filled with
/// [color] and a tick when checked.
///
/// The ring is neutral on purpose: the shop colour only arrives with the
/// tick, so a row's colour means "done", not "belongs to".
///
/// Drawn by hand because Flutter's [Checkbox] can't be styled to look like
/// the design. In `core/ui` because both item rows and onboarding use it.
class CheckCircle extends StatelessWidget {
  const CheckCircle({
    required this.value,
    required this.fillProgress,
    this.onChanged,
    this.color,
    this.tickColor,
    super.key,
  });

  final bool value;

  /// The fill when checked. Defaults to ink (onSurface), which is also what
  /// select mode uses.
  final Color? color;

  /// The tick. Defaults to the surface colour (paper on ink).
  final Color? tickColor;

  /// Called when tapped. Leave null if the whole row handles the tap
  /// instead (like in onboarding), so the circle is just a picture.
  final ValueChanged<bool?>? onChanged;
  final Animation<double> fillProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fill = color ?? scheme.onSurface;
    final ring = scheme.onSurface.withValues(
      alpha: theme.brightness == Brightness.dark ? .3 : .28,
    );
    final circle = AnimatedBuilder(
      animation: fillProgress,
      builder: (context, child) {
        // Checking has a small bounce. Unchecking doesn't, and neither does
        // anything under reduced motion.
        final eased =
            fillProgress.status == AnimationStatus.reverse ||
                AppMotion.reduced(context)
            ? fillProgress.value
            : Curves.easeOutBack.transform(fillProgress.value);
        final clamped = eased.clamp(0.0, 1.0);
        return Container(
          width: AppSizes.checkCircle,
          height: AppSizes.checkCircle,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(fill.withValues(alpha: 0), fill, clamped),
            border: Border.all(
              color: Color.lerp(ring, fill, clamped)!,
              width: 2,
            ),
          ),
          child: clamped <= 0
              ? null
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 6,
                  ),
                  child: Opacity(
                    opacity: clamped,
                    child: Transform.scale(
                      scale: eased,
                      child: CustomPaint(
                        painter: _CheckGlyphPainter(
                          color: tickColor ?? scheme.surface,
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
    final onChanged = this.onChanged;
    if (onChanged == null) return circle;
    return InkWell(
      onTap: () => onChanged(!value),
      customBorder: const CircleBorder(),
      child: circle,
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
      ..strokeWidth = 2
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
