import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// One falling piece of confetti.
///
/// Deliberately split from [_ConfettiPainter]: this class only knows "where
/// am I and how am I moving," never how it gets drawn. That split is what
/// makes [tick] a pure physics update — testable on paper, no [Canvas]
/// involved — while the painter stays a dumb renderer of whatever state
/// [tick] produced.
class ConfettiParticle {
  /// Spawns one particle at a random position along the top of [bounds],
  /// with a random sideways drift and fall speed — [random] is threaded
  /// through rather than each particle making its own [Random.new], so a
  /// whole burst can (in principle) be seeded and reproduced.
  ConfettiParticle({required this.color, required Size bounds, required Random random})
    : x = random.nextDouble() * bounds.width,
      // Spread across the top ~22% of the screen, not clustered just above
      // it — a burst that's already partway into view the instant it fires
      // reads as an explosion; confetti that all has to scroll in from
      // off-screen first reads as rain starting up.
      y = -bounds.height * 0.1 + random.nextDouble() * bounds.height * 0.22,
      vx = (random.nextDouble() - 0.5) * 260,
      vy = -40 + random.nextDouble() * 140,
      rotation = random.nextDouble() * pi * 2,
      rotationSpeed = (random.nextDouble() - 0.5) * 8,
      // The in-plane spin (rotation) orients the shape; flip is a second,
      // independent, faster rotation used only to squash its drawn width
      // (see _ConfettiPainter) — that's what makes a piece read as a
      // tumbling card catching the light edge-on, not a flat sticker
      // spinning in place like a coin on a table.
      flip = random.nextDouble() * pi * 2,
      flipSpeed = 10 + random.nextDouble() * 10,
      size = 7 + random.nextDouble() * 6;

  /// This particle's colour — one of the list's shop colours, chosen by
  /// [ConfettiBurst.fire].
  final Color color;

  /// Position, in the same coordinate space as the [Size] passed to the
  /// constructor (the overlay's own size — see [ConfettiBurst.fire]).
  double x, y;

  /// Velocity, in logical pixels per second.
  double vx, vy;

  /// Current rotation, in radians, and how fast it's currently spinning.
  double rotation, rotationSpeed;

  /// The tumble phase and speed — see the constructor's doc comment for why
  /// this is separate from [rotation] rather than reusing it.
  double flip, flipSpeed;

  /// Roughly this particle's width/height, in logical pixels. Fixed for its
  /// whole lifetime — only position, rotation, and flip animate.
  final double size;

  /// How fast falling speed increases, in px/s². Applied every [tick] so a
  /// particle reads as accelerating under gravity rather than drifting at a
  /// constant speed.
  static const double _gravity = 500;

  /// Advances this particle by [dt] seconds under gravity.
  void tick(double dt) {
    x += vx * dt;
    y += vy * dt;
    vy += _gravity * dt;
    rotation += rotationSpeed * dt;
    flip += flipSpeed * dt;
  }
}

/// Fires a one-shot, non-repeating confetti burst over the current screen.
///
/// Named `fire`, not `show` or `play`: this is an event, not a persistent
/// widget you mount — it inserts its own [OverlayEntry], drives its own
/// [Ticker], and removes itself when done. Nothing about it lives in the
/// widget tree you'd need to clean up by hand.
abstract final class ConfettiBurst {
  /// The one place this app is allowed to be theatrical (Motion &
  /// Interaction Spec §09) — restrained on purpose: a burst of a few dozen
  /// particles (the spec's own "14-20" nudged up after this read flat in
  /// hands-on testing — see decisions.md #67), only in the list's own shop
  /// colours, one 1.4s gravity fall, never repeating.
  ///
  /// Call sites are responsible for the spec's other rule, "skip entirely if
  /// reduced-motion is on" — checking `AppMotion.reduced(context)` here
  /// would make this a stateful decision hiding in a static method; better
  /// that the caller (which already reads `MediaQuery` for its own entrance
  /// animation) just doesn't call this at all when reduced motion is on.
  ///
  /// Returns a [ConfettiBurstHandle] the caller should cancel from its own
  /// `dispose()` — this burst's [Ticker] otherwise has no idea if the widget
  /// that started it goes away before the 1.4s is up (dismissed, the list
  /// un-completed, navigated away from entirely), and a live [Ticker]
  /// outliving the widget tree that created it is exactly the kind of leak
  /// the framework refuses to let a test run past.
  static ConfettiBurstHandle fire(
    BuildContext context, {
    required List<Color> colors,
  }) {
    final overlay = Overlay.of(context);
    final bounds = MediaQuery.sizeOf(context);
    final random = Random();
    final particles = List.generate(
      24 + random.nextInt(13),
      (_) => ConfettiParticle(
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

    // Shared by natural completion and an early ConfettiBurstHandle.cancel()
    // -- `finished` guards against either path tearing down an
    // already-disposed Ticker/OverlayEntry if both somehow fire.
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
        // Fades the whole burst out over its last 300ms rather than letting
        // it end abruptly — a hard cutoff at exactly 1.4s reads as a glitch,
        // not as confetti settling.
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

/// Lets whoever called [ConfettiBurst.fire] stop it early.
class ConfettiBurstHandle {
  ConfettiBurstHandle._(this._finish);

  final VoidCallback _finish;

  /// Stops the burst immediately — its [Ticker] disposed, its [OverlayEntry]
  /// removed. Safe to call after the burst already finished on its own;
  /// does nothing the second time.
  void cancel() => _finish();
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.particles);

  final List<ConfettiParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      canvas.save();
      canvas.translate(particle.x, particle.y);
      canvas.rotate(particle.rotation);
      // The tumble: scaling width by cos(flip) sweeps it from full width
      // down through zero (edge-on) and back out the other side every half
      // cycle — a 2D silhouette's version of a card tumbling end-over-end
      // through the air, not just spinning flat like a coin on a table.
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

  // Repaints on every tick regardless of particle identity — the particles
  // list is mutated in place by ConfettiBurst.fire's ticker, so there is no
  // cheaper "did anything change" check available without duplicating state.
  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}
