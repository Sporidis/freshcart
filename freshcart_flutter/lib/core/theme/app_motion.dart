import 'package:flutter/material.dart';

class AppMotion {
  AppMotion._();

  static const Duration micro = Duration(milliseconds: 120);
  static const Duration quick = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 260);
  static const Duration bouncy = Duration(milliseconds: 340);
  static const Duration sheetIn = Duration(milliseconds: 380);
  static const Duration sheetOut = Duration(milliseconds: 220);
  static const Duration celebrate = Duration(milliseconds: 900);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve pop = Curves.easeOutBack;
  static const Curve sheet = Curves.easeOutQuint;
  static const Curve press = Curves.easeOut;

  static const SpringDescription spring = SpringDescription(
    mass: 1,
    stiffness: 180,
    damping: 14,
  );

  /// Whether the viewer has asked the platform for reduced motion.
  ///
  /// The motion spec's rule: every non-essential animation checks this, and
  /// when it is on, durations collapse to [micro] and [pop]'s overshoot falls
  /// back to a plain ease. Overshoot and long travel are exactly what motion
  /// sensitivity reacts to, so honouring it is not a nicety.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], collapsed to [micro] when the viewer wants reduced motion.
  static Duration durationFor(BuildContext context, Duration duration) =>
      reduced(context) ? micro : duration;

  /// [curve], with [pop]'s overshoot dropped when motion is reduced.
  static Curve curveFor(BuildContext context, Curve curve) =>
      reduced(context) && curve == pop ? press : curve;

  /// Stagger delay for list children entering together (cap at 6 items).
  static Duration stagger(int index) =>
      Duration(milliseconds: (index.clamp(0, 5)) * 35);

  /// Stagger delay for rows revealing their multi-select circle down the
  /// list (§10) — its own, faster cadence than [stagger], which is for
  /// content entering rather than a mode-switch reveal.
  static Duration selectionStagger(int index) =>
      Duration(milliseconds: (index.clamp(0, 10)) * 25);
}
