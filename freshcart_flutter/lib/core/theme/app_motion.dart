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

  /// Stagger delay for list children entering together (cap at 6 items).
  static Duration stagger(int index) =>
      Duration(milliseconds: (index.clamp(0, 5)) * 35);
}
