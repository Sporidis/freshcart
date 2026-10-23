import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:freshcart_flutter/core/theme/reveal/reveal_wave_geometry.dart';
import 'package:freshcart_flutter/core/theme/reveal/reveal_wave_scope.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';

/// Changes [child]'s colours to a new shop colour with a circular "wave"
/// that grows out from where the user tapped.
///
/// How the trick works:
/// 1. Take a screenshot of the screen in the old colour.
/// 2. Rebuild the real screen in the new colour, underneath the screenshot.
/// 3. Cut a growing circle out of the screenshot, so the new colour shows
///    through the hole.
/// 4. When the circle covers everything, remove the screenshot.
///
/// No colours are mixed, so there's never a muddy in-between colour.
/// See decisions.md #85.
///
/// With reduced motion on, there's no wave. It does a quick fade between
/// the two colours instead.
class ShopThemeReveal extends StatefulWidget {
  /// Creates the reveal, themed to [seed].
  const ShopThemeReveal({
    required this.seed,
    required this.child,
    this.hapticsOn = true,
    super.key,
  });

  /// The shop colour to use.
  final Color seed;

  /// The content that gets recoloured.
  final Widget child;

  /// Whether to vibrate when the wave starts. Passed in by the parent so this
  /// widget doesn't need Riverpod.
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

  /// Where the last wave started, in global coordinates (a tapped pill, or
  /// a screen edge after a swipe). Read by the header's [TintWave], so both
  /// waves grow from the same point.
  Offset? get lastGlobalOrigin => _lastGlobalOrigin;
  Offset? _lastGlobalOrigin;

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
    // Normal motion: the wave was already started by [beginReveal].
    // Reduced motion: start the simple fade here instead.
    if (!AppMotion.reduced(context)) return;
    _fallbackFrom = oldWidget.seed;
    _fallbackController
      ..value = 0
      ..forward();
  }

  /// Starts the wave from [globalOrigin] (where the user tapped).
  ///
  /// Call this BEFORE changing the shop. It takes the screenshot of the
  /// current screen, and that screenshot must still show the old colour.
  /// Does nothing with reduced motion on.
  void beginReveal(Offset globalOrigin) {
    // Vibrate even with reduced motion on. Vibration isn't motion.
    if (widget.hapticsOn) unawaited(HapticFeedback.lightImpact());
    _lastGlobalOrigin = globalOrigin;
    if (AppMotion.reduced(context)) return;
    final renderObject = _boundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary || !renderObject.attached) {
      return;
    }
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final localOrigin = renderObject.globalToLocal(globalOrigin);
    // Save the old colour now. The screenshot below is async, and by the
    // time it's done, `widget.seed` is already the new colour.
    final oldSeed = widget.seed;
    // How big the circle must get to cover the screen: the distance from
    // the tap to the farthest corner.
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
                          // A small bounce at the end, same as the FAB
                          // animation.
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

/// Draws the old-colour screenshot with a round hole in it.
///
/// The hole is centred on [origin]. It grows as [progress] goes from 0 to 1
/// (a bit past 1 during the bounce). Through the hole you see the real
/// screen underneath, already in the new colour.
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

    // Only draw the screenshot outside the circle ("whole screen minus hole").
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
