import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Motion tokens for Basket. Personality: quick and confident, with a small
/// overshoot on things the USER did — never on things that merely happened.
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
  static const Curve pop = Curves.easeOutBack; // the playful one
  static const Curve sheet = Curves.easeOutQuint;
  static const Curve press = Curves.easeOut;

  static const SpringDescription spring =
      SpringDescription(mass: 1, stiffness: 180, damping: 14);

  // ---- v3 interaction tokens (match the main prototype) ----
  /// iOS sheet / push curve.
  static const Curve ios = Cubic(0.32, 0.72, 0, 1);
  /// Emphasised decelerate: shared elements, batch moves, toasts.
  static const Curve emphasized = Cubic(0.2, 0.8, 0.2, 1);
  /// Accelerating exit for sheets and the drawer.
  static const Curve exitStd = Cubic(0.4, 0, 0.6, 1);

  static const Duration shopHighlight = Duration(milliseconds: 280);
  static const Duration listSlide = Duration(milliseconds: 220); // +24ms stagger, 28px travel
  static const Duration colorWave = Duration(milliseconds: 400); // easeOutCubic, restartable
  static const Duration sharedTitle = Duration(milliseconds: 380); // emphasized
  static const Duration sheetOpen = Duration(milliseconds: 440); // ios
  static const Duration sheetClose = Duration(milliseconds: 300); // exitStd
  static const Duration drawerOpen = Duration(milliseconds: 360); // ios
  static const Duration drawerClose = Duration(milliseconds: 260); // exitStd
  static const Duration push = Duration(milliseconds: 350); // ios, outgoing -30%
  static const Duration fabRollOpen = Duration(milliseconds: 380); // ios
  static const Duration fabRollClose = Duration(milliseconds: 280); // exitStd
  static const Duration holdDelay = Duration(milliseconds: 450);
  static const Duration holdMenuIn = Duration(milliseconds: 340);
  static const Duration checkSettle = Duration(milliseconds: 750); // debounce before batch move
  static const Duration batchMove = Duration(milliseconds: 480); // emphasized, 45ms stagger
  static const Duration reflow = Duration(milliseconds: 380); // rows closing gaps
  static const Duration toastIn = Duration(milliseconds: 380);
  static const Duration toastHold = Duration(milliseconds: 3400);
  static const Duration onboardingStep = Duration(milliseconds: 340); // 36px, 40ms stagger
  static const double pressScale = 0.97;

  /// Stagger delay for list children entering together (capped at 6).
  static Duration stagger(int index) =>
      Duration(milliseconds: index.clamp(0, 5) * 35);

  /// Respect the OS reduce-motion setting: collapse everything to [micro]
  /// and drop the overshoot curve.
  static Duration duration(BuildContext context, Duration d) =>
      MediaQuery.of(context).disableAnimations ? micro : d;

  static Curve curve(BuildContext context, Curve c) =>
      MediaQuery.of(context).disableAnimations ? Curves.easeOut : c;
}
