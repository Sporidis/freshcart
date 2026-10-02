import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';

/// The round checkbox from the design: an empty circle, or filled when
/// checked.
///
/// Drawn by hand because Flutter's [Checkbox] can't be styled to look like
/// the design. In `core/ui` because both item rows and onboarding use it.
class CheckCircle extends StatelessWidget {
  const CheckCircle({
    required this.value,
    required this.fillProgress,
    this.onChanged,
    super.key,
  });

  final bool value;

  /// Called when tapped. Leave null if the whole row handles the tap
  /// instead (like in onboarding), so the circle is just a picture.
  final ValueChanged<bool?>? onChanged;
  final Animation<double> fillProgress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final circle = AnimatedBuilder(
      animation: fillProgress,
      builder: (context, child) {
        // Checking has a small bounce. Unchecking doesn't. Same as in
        // item_tile.dart.
        final eased = fillProgress.status == AnimationStatus.reverse
            ? fillProgress.value
            : Curves.easeOutBack.transform(fillProgress.value);
        final clamped = eased.clamp(0.0, 1.0);
        return Container(
          width: AppSizes.checkCircle,
          height: AppSizes.checkCircle,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Use theme colours (not fixed ones), so the circle is dark in
            // light mode and light in dark mode.
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
