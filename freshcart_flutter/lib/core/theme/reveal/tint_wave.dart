import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';

/// Fills its area with [color]. When [color] changes, the new colour grows
/// as a circle from [originOf] over the old one (the v3 header tint).
///
/// Unlike [ShopThemeReveal] this needs no screenshot: the area is one flat
/// colour, so painting the old colour and a growing circle of the new one is
/// the whole effect. A new change mid-wave restarts it from the colour it
/// was heading to, so fast taps never flash back to an older shop.
///
/// With reduced motion it's a short crossfade instead.
class TintWave extends StatefulWidget {
  const TintWave({
    required this.color,
    required this.originOf,
    this.duration = AppMotion.reveal,
    super.key,
  });

  final Color color;

  /// Where the wave should start, in global coordinates. Read when [color]
  /// changes. Null starts it from the bottom centre.
  final Offset? Function() originOf;
  final Duration duration;

  @override
  State<TintWave> createState() => _TintWaveState();
}

class _TintWaveState extends State<TintWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(vsync: this);
  late Color _from = widget.color;
  Offset? _globalOrigin;

  @override
  void didUpdateWidget(covariant TintWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.color == oldWidget.color) return;
    // Restart from where the last wave was heading, not from where it is.
    _from = oldWidget.color;
    _globalOrigin = widget.originOf();
    final reduced = AppMotion.reduced(context);
    _wave
      ..duration = reduced ? AppMotion.micro : widget.duration
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    // Expand: a childless ColoredBox/CustomPaint takes the smallest size it's
    // allowed, and an AppBar's flexibleSpace gets a loose height (0 to max),
    // which would paint the tint 0px tall.
    return SizedBox.expand(
      child: AnimatedBuilder(
        animation: _wave,
        builder: (context, _) {
          final t = AppMotion.enter.transform(_wave.value);
          if (reduced || _wave.isDismissed) {
            return ColoredBox(color: Color.lerp(_from, widget.color, t)!);
          }
          final box = context.findRenderObject() as RenderBox?;
          final origin = _globalOrigin;
          final local = box != null && box.hasSize && origin != null
              ? box.globalToLocal(origin)
              : null;
          return CustomPaint(
            painter: _WavePainter(
              from: _from,
              to: widget.color,
              origin: local,
              progress: t,
            ),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  const _WavePainter({
    required this.from,
    required this.to,
    required this.origin,
    required this.progress,
  });

  final Color from;
  final Color to;
  final Offset? origin;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = from);
    final center = origin ?? Offset(size.width / 2, size.height);
    // Far enough to cover the farthest corner.
    final reach = [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ].map((c) => (c - center).distance).reduce(math.max);
    canvas
      ..save()
      ..clipRect(rect)
      ..drawCircle(center, reach * progress, Paint()..color = to)
      ..restore();
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.from != from ||
      old.to != to ||
      old.origin != origin ||
      old.progress != progress;
}
