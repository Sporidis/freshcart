import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Owns the welcome screen's entrance/exit animation timeline.
///
/// [WelcomeScreen] only reads the exposed [Animation]s and calls [playIntro]
/// / [playExit] — it doesn't know about durations, curves, or intervals.
class WelcomeScreenAnimations {
  WelcomeScreenAnimations({required TickerProvider vsync})
    : introController = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 2800),
      ),
      exitController = AnimationController(
        vsync: vsync,
        duration: const Duration(milliseconds: 650),
      ) {
    _initIntro();
    _initExit();
  }

  // Off-screen travel distances, in logical pixels — comfortably wider than
  // any phone so the cart is fully hidden before it enters/after it leaves.
  static const double _cartOffscreenX = -340;
  static const double _cartExitOffscreenX = 420;

  final AnimationController introController;
  final AnimationController exitController;

  late final Animation<double> blobFade;
  late final Animation<double> cartFade;
  late final Animation<double> cartRollIn;
  late final Animation<double> cartRollOut;

  late final Animation<Offset> item1Path;
  late final Animation<double> item1Rotate;
  late final Animation<Offset> item2Path;
  late final Animation<double> item2Rotate;
  late final Animation<Offset> item3Path;
  late final Animation<double> item3Rotate;

  late final Animation<double> titleFade;
  late final Animation<Offset> titleSlide;
  late final Animation<double> buttonFade;
  late final Animation<Offset> buttonSlide;
  late final Animation<double> contentExitOpacity;

  /// Combined cart travel: off-screen entrance plus off-screen exit.
  double get cartOffsetX => cartRollIn.value + cartRollOut.value;

  /// Wheels spin in proportion to distance rolled, not on their own timer.
  double get wheelRotation => cartOffsetX / 12;

  /// Notifies on every tick that can move the cart, for a single repaint hook.
  Listenable get cartListenable =>
      Listenable.merge([introController, exitController]);

  void _initIntro() {
    blobFade = CurvedAnimation(
      parent: introController,
      curve: const Interval(0.0, 0.25, curve: Curves.easeOut),
    );

    cartFade = CurvedAnimation(
      parent: introController,
      curve: const Interval(0.0, 0.1, curve: Curves.easeIn),
    );
    cartRollIn = Tween<double>(begin: _cartOffscreenX, end: 0).animate(
      CurvedAnimation(
        parent: introController,
        curve: const Interval(0.0, 0.22, curve: Curves.easeOutCubic),
      ),
    );

    final item1 = _ThrownItem(
      parent: introController,
      interval: const Interval(0.25, 0.6, curve: Curves.easeInOut),
      start: const Offset(-380, -70),
      end: const Offset(-46, 0),
      arcHeight: 90,
      rotateBegin: -0.6,
      rotateEnd: -0.05,
    );
    item1Path = item1.path;
    item1Rotate = item1.rotate;

    final item2 = _ThrownItem(
      parent: introController,
      interval: const Interval(0.35, 0.72, curve: Curves.easeInOut),
      start: const Offset(400, -80),
      end: const Offset(10, 0),
      arcHeight: 100,
      rotateBegin: 0.5,
      rotateEnd: 0.05,
    );
    item2Path = item2.path;
    item2Rotate = item2.rotate;

    final item3 = _ThrownItem(
      parent: introController,
      interval: const Interval(0.45, 0.82, curve: Curves.easeInOut),
      start: const Offset(-360, -75),
      end: const Offset(48, 0),
      arcHeight: 95,
      rotateBegin: -0.4,
      rotateEnd: 0.1,
    );
    item3Path = item3.path;
    item3Rotate = item3.rotate;

    titleFade = CurvedAnimation(
      parent: introController,
      curve: const Interval(0.78, 0.94, curve: Curves.easeOut),
    );
    titleSlide = Tween(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: introController,
        curve: const Interval(0.78, 0.94, curve: Curves.easeOutCubic),
      ),
    );

    buttonFade = CurvedAnimation(
      parent: introController,
      curve: const Interval(0.92, 1.0, curve: Curves.easeOut),
    );
    buttonSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: introController,
        curve: const Interval(0.92, 1.0, curve: Curves.easeOutCubic),
      ),
    );
  }

  void _initExit() {
    cartRollOut = Tween<double>(begin: 0, end: _cartExitOffscreenX).animate(
      CurvedAnimation(parent: exitController, curve: Curves.easeInCubic),
    );
    contentExitOpacity = CurvedAnimation(
      parent: exitController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ).drive(Tween(begin: 1, end: 0));
  }

  void playIntro() => introController.forward();

  Future<void> playExit() => exitController.forward();

  void dispose() {
    introController.dispose();
    exitController.dispose();
  }
}

/// A single item's thrown-in-from-off-screen path: a parabolic arc, not a
/// straight fall, plus a tumble that settles as it lands.
class _ThrownItem {
  _ThrownItem({
    required Animation<double> parent,
    required Interval interval,
    required Offset start,
    required Offset end,
    required double arcHeight,
    required double rotateBegin,
    required double rotateEnd,
  }) {
    final curved = CurvedAnimation(parent: parent, curve: interval);
    path = _ArcOffsetTween(
      begin: start,
      end: end,
      arcHeight: arcHeight,
    ).animate(curved);
    rotate = Tween<double>(begin: rotateBegin, end: rotateEnd).animate(curved);
  }

  late final Animation<Offset> path;
  late final Animation<double> rotate;
}

/// Straight horizontal travel with a parabolic vertical arc, so items read as
/// thrown into the cart rather than dropped straight down.
class _ArcOffsetTween extends Tween<Offset> {
  _ArcOffsetTween({
    required super.begin,
    required super.end,
    required this.arcHeight,
  });

  final double arcHeight;

  @override
  Offset lerp(double t) {
    final dx = begin!.dx + (end!.dx - begin!.dx) * t;
    final linearDy = begin!.dy + (end!.dy - begin!.dy) * t;
    final arc = -arcHeight * math.sin(math.pi * t);
    return Offset(dx, linearDy + arc);
  }
}
