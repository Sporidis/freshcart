import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';

/// Retints [child] to [seed] with a colour reveal anchored to wherever the
/// change was triggered, instead of a flat crossfade.
///
/// Replaces the plain `AnimatedTheme` this used to be (decisions #71). That
/// approach lerps every `ColorScheme` role independently through RGB, which
/// visibly dips through a muddy, desaturated colour between two saturated,
/// differently-hued shops. This widget never blends colours at all: a frozen
/// snapshot of the *old* theme sits on top of the live body (already
/// rebuilt in the *new* theme), with a circular hole growing through the
/// snapshot from the tap that caused the change. Every visible pixel is
/// always fully one theme or the other -- see decisions #85.
///
/// Reduced-motion viewers skip the spatial reveal (it's exactly the kind of
/// motion `AppMotion.reduced` exists to suppress) and get a quick crossfade
/// instead -- but even that fallback interpolates the *seed colour* through
/// HSL rather than lerping the derived scheme, for the same muddy-midpoint
/// reason.
class ShopThemeReveal extends StatefulWidget {
  /// Creates the reveal, themed to [seed].
  const ShopThemeReveal({
    required this.seed,
    required this.child,
    this.hapticsOn = true,
    super.key,
  });

  /// The seed colour to build this subtree's `ColorScheme` from.
  final Color seed;

  /// The retinted content.
  final Widget child;

  /// Whether [beginReveal] should fire a light haptic when it starts.
  /// Resolved by the caller (a plain `bool`, not a Riverpod read in here) --
  /// same reasoning `RecentlyChecked` gives for staying `AppMotion`-free
  /// itself: this widget has no other Riverpod dependency, and one haptics
  /// check isn't worth giving it one.
  final bool hapticsOn;

  @override
  State<ShopThemeReveal> createState() => ShopThemeRevealState();
}

class ShopThemeRevealState extends State<ShopThemeReveal>
    with TickerProviderStateMixin {
  final GlobalKey _boundaryKey = GlobalKey();

  late final AnimationController _revealController;
  ui.Image? _frozenSnapshot;
  Offset? _localOrigin;
  RevealWaveGeometry? _waveGeometry;

  late final AnimationController _fallbackController;
  Color? _fallbackFrom;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: AppMotion.reveal,
    )..addStatusListener(_onRevealStatusChanged);
    _fallbackController = AnimationController(
      vsync: this,
      duration: AppMotion.micro,
    );
  }

  @override
  void didUpdateWidget(covariant ShopThemeReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed.toARGB32() == widget.seed.toARGB32()) return;
    // Not reduced motion: [beginReveal] already handled it -- the caller
    // invokes that *before* the state change that produced this rebuild.
    if (!AppMotion.reduced(context)) return;
    _fallbackFrom = oldWidget.seed;
    _fallbackController
      ..value = 0
      ..forward();
  }

  /// Anchors a spatial reveal at [globalOrigin].
  ///
  /// Call this *before* mutating whatever state will change [seed] on the
  /// next build -- it snapshots the subtree's current (pre-change) pixels,
  /// and a snapshot taken after the change would freeze the new colours
  /// instead of the old ones. No-ops under reduced motion, so callers don't
  /// need their own check.
  void beginReveal(Offset globalOrigin) {
    // Fires regardless of reduced motion -- a physical "the tap landed" cue
    // is a separate accessibility axis from the spatial animation itself,
    // and reduced-motion viewers still get the (quicker) cross-fade fallback.
    if (widget.hapticsOn) unawaited(HapticFeedback.lightImpact());
    if (AppMotion.reduced(context)) return;
    final renderObject = _boundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary || !renderObject.attached) {
      return;
    }
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final localOrigin = renderObject.globalToLocal(globalOrigin);
    // Captured now, before the caller mutates whatever state produces the
    // next `widget.seed` -- by the time the snapshot below resolves,
    // `widget.seed` will already be the new one.
    final oldSeed = widget.seed;
    final size = renderObject.size;
    final maxRadius = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((corner) => (corner - localOrigin).distance).reduce(math.max);
    unawaited(
      renderObject.toImage(pixelRatio: pixelRatio).then((image) {
        if (!mounted) {
          image.dispose();
          return;
        }
        _frozenSnapshot?.dispose();
        setState(() {
          _frozenSnapshot = image;
          _localOrigin = localOrigin;
          _waveGeometry = RevealWaveGeometry(
            globalOrigin: globalOrigin,
            maxRadius: maxRadius,
            oldSeed: oldSeed,
            newSeed: widget.seed,
          );
        });
        _revealController
          ..value = 0
          ..forward();
      }),
    );
  }

  void _onRevealStatusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final snapshot = _frozenSnapshot;
    if (snapshot == null) return;
    setState(() {
      _frozenSnapshot = null;
      _waveGeometry = null;
    });
    snapshot.dispose();
  }

  @override
  void dispose() {
    _revealController.dispose();
    _fallbackController.dispose();
    _frozenSnapshot?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return AnimatedBuilder(
      animation: Listenable.merge([_revealController, _fallbackController]),
      builder: (context, _) {
        final fallbackFrom = _fallbackFrom;
        final seed = (fallbackFrom != null && _fallbackController.isAnimating)
            ? AppColors.lerpHsl(
                fallbackFrom,
                widget.seed,
                AppMotion.enter.transform(_fallbackController.value),
              )
            : widget.seed;
        final themed = brightness == Brightness.dark
            ? AppTheme.dark(seed)
            : AppTheme.light(seed);
        final wavePop = AppMotion.curveFor(context, AppMotion.pop);

        return RevealWaveScope(
          geometry: _waveGeometry,
          controller: _revealController,
          curve: wavePop,
          child: Theme(
            data: themed,
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(key: _boundaryKey, child: widget.child),
                if (_frozenSnapshot != null && _localOrigin != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _RevealPunchPainter(
                          image: _frozenSnapshot!,
                          origin: _localOrigin!,
                          // A slight overshoot-and-settle, not a plain
                          // deceleration -- the same curve family behind
                          // the FAB's own checked-state pop, so this
                          // headline transition shares its spring.
                          progress: wavePop.transform(_revealController.value),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Paints [image] -- a frozen snapshot of the body in its *previous* theme
/// -- with a circular hole punched through it, centred on [origin] and
/// growing as [progress] goes 0 -> 1 (and, thanks to the overshoot curve
/// this is driven with, slightly past 1 before settling). Whatever shows
/// through the hole is the live body underneath, already rebuilt in the new
/// theme, so this never blends the two: each pixel is always fully one
/// theme or the other -- exactly the new shop's colour wherever the wave has
/// reached, exactly the old one everywhere it hasn't yet, no in-between
/// glow or ring dressing it up (dropped after it read as a glitchy edge
/// rather than a shockwave -- decisions #88's own addition, undone).
class _RevealPunchPainter extends CustomPainter {
  const _RevealPunchPainter({
    required this.image,
    required this.origin,
    required this.progress,
  });

  final ui.Image image;
  final Offset origin;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    final maxRadius = corners
        .map((corner) => (corner - origin).distance)
        .reduce(math.max);
    final radius = maxRadius * progress;

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final fullRect = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addOval(Rect.fromCircle(center: origin, radius: radius));
    final visible = Path.combine(PathOperation.difference, fullRect, hole);
    canvas.clipPath(visible);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint(),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RevealPunchPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.origin != origin ||
      oldDelegate.progress != progress;
}

/// The geometry of one in-flight [ShopThemeReveal] wave, in global
/// coordinates so a descendant anywhere in the subtree can compare its own
/// position against it without needing to know about [ShopThemeReveal]'s
/// own local coordinate space (its `RepaintBoundary`, its `_boundaryKey`).
///
/// Exists so a "hero" widget with its own independent reaction to
/// `Theme.of(context)` changing -- unlike the bulk of this subtree, which
/// just passively renders whatever theme it currently sees, and is
/// perfectly well served by the cosmetic snapshot-and-mask the rest of
/// [ShopThemeReveal] uses -- can retint itself for real only once the wave
/// has actually reached it, instead of reacting the instant the ambient
/// `Theme` changes everywhere at once. See [WaveThemed], and decisions #89.
@immutable
class RevealWaveGeometry {
  const RevealWaveGeometry({
    required this.globalOrigin,
    required this.maxRadius,
    required this.oldSeed,
    required this.newSeed,
  });

  /// Where the wave started (a tap, or a screen edge for a swipe), in
  /// global coordinates.
  final Offset globalOrigin;

  /// The radius the wave needs to reach to have covered the whole
  /// [ShopThemeReveal] subtree -- the same "farthest corner" formula
  /// `_RevealPunchPainter` uses for its own mask, just computed once in
  /// global terms instead of every paint in local ones.
  final double maxRadius;

  /// The seed colour anything not yet reached by the wave should render as.
  final Color oldSeed;

  /// The seed colour anything the wave has already reached should render as.
  final Color newSeed;
}

/// Publishes the currently in-flight [ShopThemeReveal] wave's
/// [RevealWaveGeometry] (null when no wave is playing) and its driving
/// [AnimationController] to descendants -- an [InheritedNotifier] rather
/// than a plain [InheritedWidget] because dependents need to rebuild on
/// every animation frame the controller ticks, not just when a new wave
/// starts.
class RevealWaveScope extends InheritedNotifier<AnimationController> {
  /// Creates the scope. [controller] is the same one driving the visual
  /// mask, so a dependent's own gating rides the exact same spring.
  const RevealWaveScope({
    required this.geometry,
    required AnimationController controller,
    required this.curve,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  /// The live wave's geometry, or null while no reveal is in flight (in
  /// which case a dependent should just render its ordinary, settled
  /// theme -- there is nothing left to gate on).
  final RevealWaveGeometry? geometry;

  /// The curve [controller]'s progress is read through -- the same
  /// overshoot spring the visual mask itself uses, so a dependent's own
  /// retint lands in step with it.
  final Curve curve;

  /// The controller driving the wave -- read `.value` (curved through
  /// [curve]) for the live, 0-to-just-past-1 progress.
  AnimationController get controller => notifier!;

  static RevealWaveScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RevealWaveScope>();

  // InheritedNotifier's own default only compares `notifier` -- since that's
  // the same AnimationController for this reveal's entire lifetime, the one
  // moment [geometry] actually changes (null -> real, at the very start of
  // a wave) would otherwise never tell already-built dependents like
  // [WaveThemed] to rebuild. They'd still catch up a frame later once the
  // controller starts ticking (that path is separate, and unconditional),
  // but that's a real, visible one-frame lag on exactly the moment meant to
  // read as "the wave just started" -- worth not having at all.
  @override
  bool updateShouldNotify(covariant RevealWaveScope oldWidget) =>
      super.updateShouldNotify(oldWidget) ||
      oldWidget.geometry != geometry ||
      oldWidget.curve != curve;
}
