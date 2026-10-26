import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/core/theme/reveal/reveal_wave_geometry.dart';
import 'package:freshcart_flutter/core/theme/reveal/reveal_wave_scope.dart';
import 'package:freshcart_flutter/core/theme/reveal/shop_theme_reveal.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';

/// Changes [child]'s colour only when the shop wave actually reaches it.
///
/// Why this is needed: [ShopThemeReveal] really changes the theme of the
/// whole screen at once, and hides that behind a screenshot. That works for
/// normal widgets. But a widget that animates its own colour (like the FAB)
/// would start changing immediately, before the wave gets to it.
///
/// This widget checks its own position on screen against the wave. Before
/// the wave reaches it, it keeps the old colour. After, the new one.
/// See decisions.md #89.
///
/// Only use it for a few special widgets. Checking positions every frame is
/// too expensive for every row in a list.
class WaveThemed extends StatefulWidget {
  /// Wraps [child] so it changes colour when the wave reaches it.
  ///
  /// [bounce]: the widget does a small "pop" (grows a bit, then shrinks
  /// back) the moment a new wave starts.
  ///
  /// [localReveal]: instead of switching colour all at once, the circle
  /// moves through the widget itself, so it can be half old colour, half
  /// new. To do this, [child] is built twice (old colour below, new colour
  /// on top, cut to the circle). So don't use it if [child] has a text
  /// field or focus, those can't exist twice. `QuickAddBar` only turns
  /// this on while it's collapsed, for that reason.
  const WaveThemed({
    required this.child,
    this.bounce = false,
    this.localReveal = false,
    super.key,
  });

  final Widget child;
  final bool bounce;
  final bool localReveal;

  @override
  State<WaveThemed> createState() => _WaveThemedState();
}

class _WaveThemedState extends State<WaveThemed>
    with SingleTickerProviderStateMixin {
  final GlobalKey _positionKey = GlobalKey();

  /// The last wave we saw. A new wave creates a new object, so if the
  /// object is different (`identical` is false), a new wave just started.
  RevealWaveGeometry? _lastGeometry;

  /// The bounce: size 1.0 -> 1.08 -> 1.0.
  ///
  /// One curve over the whole animation, not one per step. Separate curves
  /// made it stutter at the top.
  late final AnimationController _bounce = AnimationController(
    vsync: this,
    duration: AppMotion.quick,
  );
  late final Animation<double> _bounceScale =
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 1),
      ]).animate(
        CurvedAnimation(parent: _bounce, curve: Curves.easeOut),
      );

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.bounce) return;
    final geometry = RevealWaveScope.of(context)?.geometry;
    if (geometry != null && !identical(geometry, _lastGeometry)) {
      _bounce.forward(from: 0);
    }
    _lastGeometry = geometry;
  }

  Widget _themedCopy(Color seed, Brightness brightness) => Theme(
    data: brightness == Brightness.dark
        ? AppTheme.dark(seed)
        : AppTheme.light(seed),
    child: widget.child,
  );

  @override
  Widget build(BuildContext context) {
    final scope = RevealWaveScope.of(context);
    final geometry = scope?.geometry;
    final Widget themed;
    if (scope == null || geometry == null) {
      // No wave playing: just use the normal theme.
      themed = KeyedSubtree(key: _positionKey, child: widget.child);
    } else {
      // Our position from the last frame. Fine, because this widget doesn't
      // move during the wave.
      final box = _positionKey.currentContext?.findRenderObject();
      final progress = scope.curve.transform(scope.controller.value);
      final radius = geometry.maxRadius * progress;
      final brightness = Theme.of(context).brightness;

      if (widget.localReveal) {
        // Two copies of the child: old colour below, new colour on top,
        // cut to the wave's circle.
        final localOrigin = (box is RenderBox && box.hasSize)
            ? box.globalToLocal(geometry.globalOrigin)
            // Not laid out yet: just show the old colour for this frame.
            : null;
        themed = KeyedSubtree(
          key: _positionKey,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              IgnorePointer(
                child: _themedCopy(geometry.oldSeed, brightness),
              ),
              if (localOrigin != null)
                ClipPath(
                  clipper: _CircleClipper(
                    center: localOrigin,
                    radius: radius,
                  ),
                  child: _themedCopy(geometry.newSeed, brightness),
                ),
            ],
          ),
        );
      } else {
        // Is our centre inside the wave's circle yet?
        final myCenter = (box is RenderBox && box.hasSize)
            ? box.localToGlobal(box.size.center(Offset.zero))
            // Not laid out yet: pretend we're already covered, so we don't
            // flash the old colour for one frame.
            : geometry.globalOrigin;
        final covered = (myCenter - geometry.globalOrigin).distance <= radius;
        final seed = covered ? geometry.newSeed : geometry.oldSeed;
        themed = KeyedSubtree(
          key: _positionKey,
          child: _themedCopy(seed, brightness),
        );
      }
    }

    if (!widget.bounce) return themed;
    return AnimatedBuilder(
      animation: _bounce,
      builder: (context, child) =>
          Transform.scale(scale: _bounceScale.value, child: child),
      child: themed,
    );
  }
}

/// Cuts a widget to a circle at [center] with [radius]. Used by
/// [WaveThemed]'s `localReveal`.
class _CircleClipper extends CustomClipper<Path> {
  const _CircleClipper({required this.center, required this.radius});

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: center, radius: radius));

  @override
  bool shouldReclip(covariant _CircleClipper oldClipper) =>
      oldClipper.center != center || oldClipper.radius != radius;
}
