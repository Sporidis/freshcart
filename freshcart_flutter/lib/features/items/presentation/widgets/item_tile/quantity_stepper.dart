import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_radii.dart';

/// A pill with "−  2  +" to change the quantity.
///
/// The − and + are drawn by hand, not with [Icons.add]/[Icons.remove],
/// because the icon font's lines are too thin for the design.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    required this.quantity,
    this.onDecrement,
    this.onIncrement,
    this.decreaseLabel,
    this.increaseLabel,
    super.key,
  });

  /// What a screen reader calls the − and + ("Fewer", "More"). The glyphs
  /// are drawn, so without these they'd be unnamed buttons.
  final String? decreaseLabel;
  final String? increaseLabel;

  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  // 30 px buttons (IconButton's default 48 px is too big here).
  static const _circleSize = 30.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        // Theme border colour, so it's visible in dark mode too.
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            isAdd: false,
            color: scheme.onSurface,
            onTap: onDecrement,
            label: decreaseLabel,
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Theme colours (like CheckCircle), so it's visible in dark
              // mode too.
              color: scheme.onSurface,
            ),
            child: _StepperButton(
              isAdd: true,
              color: scheme.surface,
              onTap: onIncrement,
              label: increaseLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.isAdd,
    required this.color,
    required this.onTap,
    this.label,
  });

  final bool isAdd;
  final Color color;
  final VoidCallback? onTap;
  final String? label;

  static const _tapSize = QuantityStepper._circleSize;
  static const _glyphSize = 10.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: _tapSize,
          height: _tapSize,
          child: Center(
            child: CustomPaint(
              size: const Size.square(_glyphSize),
              painter: _StepperGlyphPainter(isAdd: isAdd, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepperGlyphPainter extends CustomPainter {
  const _StepperGlyphPainter({required this.isAdd, required this.color});

  final bool isAdd;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paint);
    if (isAdd) {
      canvas.drawLine(
        Offset(center.dx, 0),
        Offset(center.dx, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StepperGlyphPainter old) =>
      old.isAdd != isAdd || old.color != color;
}
