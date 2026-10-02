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
  // The colour wave when switching shops. Slow enough to see it cross the
  // whole screen. See decisions.md #85 and #89.
  static const Duration reveal = Duration(milliseconds: 700);

  // Moving between onboarding steps. The old page leaves quickly, then the
  // new one comes in a bit later, so they never overlap.
  static const Duration stepOut = Duration(milliseconds: 200);
  static const Duration stepIn = Duration(milliseconds: 320);
  static const Duration stepInDelay = Duration(milliseconds: 60);

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

  /// Whether the user turned on "reduce motion" in the phone's settings.
  ///
  /// If so, animations become very short ([micro]) and don't bounce. Some
  /// people get dizzy from motion, so every animation should respect this.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Returns [duration], or [micro] if reduced motion is on.
  static Duration durationFor(BuildContext context, Duration duration) =>
      reduced(context) ? micro : duration;

  /// Returns [curve], but without the bounce of [pop] if reduced motion is on.
  static Curve curveFor(BuildContext context, Curve curve) =>
      reduced(context) && curve == pop ? press : curve;

  /// Delay for the item at [index], so list items appear one after another
  /// instead of all at once. Stops growing after 6 items.
  static Duration stagger(int index) =>
      Duration(milliseconds: (index.clamp(0, 5)) * 35);

  /// Like [stagger], but faster. Used when entering select mode, so the
  /// select circles appear row by row.
  static Duration selectionStagger(int index) =>
      Duration(milliseconds: (index.clamp(0, 10)) * 25);
}
