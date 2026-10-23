import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';

/// Draws a strike-through across [child] as [progress] runs 0 to 1.
///
/// The line is drawn left to right, like crossing something off with a pen.
/// [TextDecoration.lineThrough] can't animate, it would just appear.
class StrikeThrough extends StatelessWidget {
  const StrikeThrough({
    required this.progress,
    required this.color,
    required this.child,
    super.key,
  });

  final Animation<double> progress;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // With reduced motion, skip the animation but still show the line,
    // because it tells the user the item is done.
    if (AppMotion.reduced(context)) {
      return CustomPaint(
        foregroundPainter: _StrikePainter(
          progress: progress.value > 0 ? 1 : 0,
          color: color,
        ),
        child: child,
      );
    }
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) => CustomPaint(
        foregroundPainter: _StrikePainter(
          progress: progress.value,
          color: color,
        ),
        child: child,
      ),
      child: child,
    );
  }
}

class _StrikePainter extends CustomPainter {
  const _StrikePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final y = size.height / 2;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width * progress.clamp(0, 1), y),
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_StrikePainter old) =>
      old.progress != progress || old.color != color;
}
