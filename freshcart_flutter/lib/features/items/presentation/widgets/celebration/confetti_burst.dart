import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// One falling piece of confetti.
///
/// Only knows where it is and how it moves. Drawing is done by
/// [_ConfettiPainter]. That keeps [tick] simple maths, easy to test without
/// a [Canvas].
class _ConfettiParticle {
  /// Creates one piece at a random spot near the top of [bounds], with a
  /// random sideways and falling speed.
  ///
  /// [random] is passed in (not created per piece), so a whole burst could
  /// be made repeatable with a fixed seed.
  _ConfettiParticle({
    required this.color,
    required Size bounds,
    required Random random,
  }) : x = random.nextDouble() * bounds.width,
       // Start somewhere in the top 22% of the screen (not above it), so
       // it looks like a burst, not like rain starting.
       y = -bounds.height * 0.1 + random.nextDouble() * bounds.height * 0.22,
       vx = (random.nextDouble() - 0.5) * 260,
       vy = -40 + random.nextDouble() * 140,
       rotation = random.nextDouble() * pi * 2,
       rotationSpeed = (random.nextDouble() - 0.5) * 8,
       // Two rotations: `rotation` turns the piece flat, `flip` makes it
       // look like it tumbles (by squashing its width, see
       // _ConfettiPainter). Without flip it would look like a flat sticker.
       flip = random.nextDouble() * pi * 2,
       flipSpeed = 10 + random.nextDouble() * 10,
       size = 7 + random.nextDouble() * 6;

  /// This piece's colour (one of the list's shop colours).
  final Color color;

  /// Position on the overlay.
  double x, y;

  /// Velocity, in logical pixels per second.
  double vx, vy;

  /// Current rotation (in radians), and how fast it spins.
  double rotation, rotationSpeed;

  /// The tumble (see the comment in the constructor).
  double flip, flipSpeed;

  /// Size in pixels. Doesn't change.
  final double size;

  /// Gravity (px/s²). Makes pieces fall faster and faster, like real ones.
  static const double _gravity = 500;

  /// Moves this piece forward by [dt] seconds.
  void tick(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy += _gravity * dt;
    rotation += rotationSpeed * dt;
    flip += flipSpeed * dt;
  }
}

/// Shows one confetti burst over the screen.
///
/// Not a widget you put in the tree. [fire] adds its own [OverlayEntry],
/// runs its own [Ticker], and removes itself when it's done.
abstract final class ConfettiBurst {
  /// Starts the burst: a few dozen pieces in the list's shop [colors],
  /// falling for 1.4 s, once (decisions.md #67).
  ///
  /// Doesn't check reduced motion itself. The caller must not call this
  /// when reduced motion is on.
  ///
  /// Returns a [ConfettiBurstHandle]. Call `cancel()` on it in your
  /// `dispose()`. Otherwise the animation keeps running after your widget
  /// is gone (a leak, and tests will fail).
  static ConfettiBurstHandle fire(
    BuildContext context, {
    required List<Color> colors,
  }) {
    final overlay = Overlay.of(context);
    final bounds = MediaQuery.sizeOf(context);
    final random = Random();
    final particles = List.generate(
      24 + random.nextInt(13),
      (_) => _ConfettiParticle(
        color: colors[random.nextInt(colors.length)],
        bounds: bounds,
        random: random,
      ),
    );

    late final OverlayEntry entry;
    late final Ticker ticker;
    const totalDuration = Duration(milliseconds: 1400);
    Duration? lastElapsed;
    var finished = false;

    // Cleans up. Called when the animation ends, or by cancel(). `finished`
    // makes sure it only runs once.
    void finish() {
      if (finished) return;
      finished = true;
      ticker
        ..stop()
        ..dispose();
      entry.remove();
    }

    void onTick(Duration elapsed) {
      final dtSeconds =
          (elapsed - (lastElapsed ?? elapsed)).inMicroseconds / 1e6;
      lastElapsed = elapsed;
      for (final particle in particles) {
        particle.tick(dtSeconds);
      }
      entry.markNeedsBuild();
      if (elapsed >= totalDuration) finish();
    }

    ticker = Ticker(onTick)..start();
    entry = OverlayEntry(
      builder: (context) {
        // Fade out during the last 300 ms, so it doesn't stop suddenly.
        final elapsed = lastElapsed ?? Duration.zero;
        final remaining = totalDuration - elapsed;
        final fade = (remaining.inMilliseconds / 300).clamp(0.0, 1.0);
        return IgnorePointer(
          child: Opacity(
            opacity: fade,
            child: CustomPaint(
              size: bounds,
              painter: _ConfettiPainter(particles),
            ),
          ),
        );
      },
    );
    overlay.insert(entry);
    return ConfettiBurstHandle._(finish);
  }
}

/// Returned by [ConfettiBurst.fire], to stop the burst early.
class ConfettiBurstHandle {
  ConfettiBurstHandle._(this._finish);

  final VoidCallback _finish;

  /// Stops the burst now. Safe to call more than once, or after it ended.
  void cancel() => _finish();
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles);

  final List<_ConfettiParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      canvas.save();
      canvas.translate(particle.x, particle.y);
      canvas.rotate(particle.rotation);
      // The tumble: width × cos(flip) goes from full width to 0 and back,
      // which looks like a piece of paper flipping over in the air.
      canvas.scale(cos(particle.flip), 1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 0.6,
          ),
          const Radius.circular(1.5),
        ),
        Paint()..color = particle.color,
      );
      canvas.restore();
    }
  }

  // Always repaint. The pieces are changed in place every frame, so there's
  // no cheap way to check if something changed.
  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}
