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

  // ---- Design v3 interaction tokens (the main prototype) ----
  // Where these disagree with the older tokens above, the v3 value wins for
  // anything built or restyled to the v3 design.

  /// iOS sheet and push curve.
  static const Curve ios = Cubic(0.32, 0.72, 0, 1);

  /// Emphasised decelerate: shared elements, batch moves, toasts.
  static const Curve emphasized = Cubic(0.2, 0.8, 0.2, 1);

  /// Accelerating exit for sheets and the drawer.
  static const Curve exitStd = Cubic(0.4, 0, 0.6, 1);

  static const Duration shopHighlight = Duration(milliseconds: 280);
  static const Duration listSlide = Duration(
    milliseconds: 220,
  ); // +24ms stagger, 28px travel
  static const Duration colorWave = Duration(milliseconds: 400); // restartable
  static const Duration sharedTitle = Duration(milliseconds: 380);
  static const Duration sheetOpen = Duration(milliseconds: 440);
  static const Duration sheetClose = Duration(milliseconds: 300);
  static const Duration drawerOpen = Duration(milliseconds: 360);
  static const Duration drawerClose = Duration(milliseconds: 260);
  static const Duration push = Duration(milliseconds: 350);
  static const Duration fabRollOpen = Duration(milliseconds: 380);
  static const Duration fabRollClose = Duration(milliseconds: 280);
  static const Duration holdDelay = Duration(milliseconds: 450);
  static const Duration holdMenuIn = Duration(milliseconds: 340);

  /// The ink mode bar replacing the header (Select, Rearrange).
  static const Duration modeBar = Duration(milliseconds: 340);

  /// Quiet period after the last tick before checked rows move to Done.
  static const Duration checkSettle = Duration(milliseconds: 750);

  /// [checkSettle] under reduced motion.
  static const Duration checkSettleReduced = Duration(milliseconds: 300);
  static const Duration batchMove = Duration(milliseconds: 480); // 45ms stagger
  static const Duration reflow = Duration(milliseconds: 380);
  static const Duration toastIn = Duration(milliseconds: 380);
  static const Duration toastHold = Duration(milliseconds: 3400);
  static const Duration onboardingStep = Duration(
    milliseconds: 340,
  ); // 36px, 40ms stagger
  static const double pressScale = 0.97;

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
