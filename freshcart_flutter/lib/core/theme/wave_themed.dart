import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/core/theme/shop_theme_reveal.dart';

/// Retints [child] the instant the nearest ancestor [ShopThemeReveal]'s wave
/// physically reaches its position -- not the moment the shop filter
/// changes, the way everything else under that reveal does.
///
/// [ShopThemeReveal] itself is cosmetic for the bulk of its subtree: the
/// ambient `Theme` flips to the new seed everywhere, instantly, and a
/// frozen snapshot with a growing hole in it just *looks* like the change
/// is travelling outward. That's indistinguishable from the real thing for
/// content with no reaction of its own to `Theme.of(context)` changing --
/// but a widget that *does* have its own independent colour transition
/// sees that change the instant it happens everywhere at once, before the
/// wave has visibly gotten anywhere near it (decisions #89).
///
/// [WaveThemed] fixes that for the specific widgets that need it, by
/// finding its own position and comparing it against the reveal's live
/// geometry: still uncovered, it renders [child] under the *old* seed;
/// covered, the *new* one -- an instant flip at the true moment the wave
/// arrives, not a fade of its own. Wrapping every row of a long list in
/// this would mean a position lookup and a rebuild per row per frame; the
/// snapshot-and-mask [ShopThemeReveal] already does is the right tool for
/// that. This is for the few "hero" elements that actually need to be
/// physically correct, not merely look it.
class WaveThemed extends StatefulWidget {
  /// Wraps [child] in the wave-gated retint. Set [bounce] for a small,
  /// one-shot scale pop the instant a new wave *starts* -- the moment the
  /// shop-filter tap or swipe fired, the same beat the haptic in
  /// [ShopThemeReveal.beginReveal] fires on. Deliberately not tied to
  /// [child]'s own colour arriving (that's still gated on real coverage,
  /// unaffected by this): the bounce is this widget's reaction to being
  /// interacted with, not to its own retint finishing.
  const WaveThemed({required this.child, this.bounce = false, super.key});

  final Widget child;
  final bool bounce;

  @override
  State<WaveThemed> createState() => _WaveThemedState();
}

class _WaveThemedState extends State<WaveThemed>
    with SingleTickerProviderStateMixin {
  final GlobalKey _positionKey = GlobalKey();

  /// The last [RevealWaveGeometry] instance seen -- [ShopThemeReveal]
  /// constructs a fresh one each time a wave starts and reuses it for every
  /// tick during that wave, so comparing by identity (not value) is what
  /// tells "a new wave just began" apart from "the same wave ticked".
  RevealWaveGeometry? _lastGeometry;

  /// Same 1.0 -> 1.08 -> 1.0 shape `item_tile.dart`'s own
  /// `_iconPop`/`_iconPopOvershoot` uses for its swipe-delete icon pop --
  /// including the same structural choice of *where* the easing goes: one
  /// curve wrapping the whole controller, with the two tween stages left
  /// linear. Curving each stage on its own (tried first) put a
  /// deceleration right at the peak and another right after it -- two
  /// separately-easing arcs stitched together read as a hitch/stutter at
  /// the top rather than one smooth grow-and-shrink.
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

  @override
  Widget build(BuildContext context) {
    final subtree = KeyedSubtree(key: _positionKey, child: widget.child);

    final scope = RevealWaveScope.of(context);
    final geometry = scope?.geometry;
    final Widget themed;
    if (scope == null || geometry == null) {
      // No wave in flight: nothing to gate on, so no theme override --
      // just the ordinary ambient one, already the settled, correct value.
      themed = subtree;
    } else {
      // Read from the *previous* frame's layout, which is safe and
      // standard for a position that doesn't move frame to frame -- by
      // the time this rebuilds (every tick of the wave), the subtree has
      // already been laid out at least once.
      final box = _positionKey.currentContext?.findRenderObject();
      final myCenter = (box is RenderBox && box.hasSize)
          ? box.localToGlobal(box.size.center(Offset.zero))
          // Not laid out yet (this widget's very first frame): assume
          // already covered rather than flashing the old colour for one
          // frame before the real position is known.
          : geometry.globalOrigin;

      final progress = scope.curve.transform(scope.controller.value);
      final radius = geometry.maxRadius * progress;
      final covered = (myCenter - geometry.globalOrigin).distance <= radius;
      final seed = covered ? geometry.newSeed : geometry.oldSeed;

      final brightness = Theme.of(context).brightness;
      themed = Theme(
        data: brightness == Brightness.dark
            ? AppTheme.dark(seed)
            : AppTheme.light(seed),
        child: subtree,
      );
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
