import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';

/// Draws a strike-through across [child] as [progress] runs 0 to 1.
///
/// Painted rather than set as [TextDecoration.lineThrough], which would snap
/// on the frame the value flips. The line wipes left to right instead, which
/// is what makes checking something off feel like an action rather than a
/// state change.
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
    // With motion reduced there is nothing to wipe, so it is drawn or it is
    // not -- but it is still drawn, because it carries meaning, not polish.
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

/// Fades [child] toward [maxFade] as [progress] runs 0 to 1 -- the "already
/// in the trolley" treatment for a checked-off row, meant to pair with
/// [StrikeThrough] driven by the same [progress].
///
/// Kept separate from [StrikeThrough] rather than folded into one widget:
/// the strike only ever wraps a name's [Text], while this fade typically
/// wraps a whole row (dot, quantity, everything), so the two apply at
/// different points in a row's widget tree.
class CheckedFade extends StatelessWidget {
  const CheckedFade({
    required this.progress,
    required this.child,
    this.maxFade = 0.55,
    super.key,
  });

  final Animation<double> progress;
  final Widget child;
  final double maxFade;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) =>
          Opacity(opacity: 1 - (progress.value * maxFade), child: child),
      child: child,
    );
  }
}
