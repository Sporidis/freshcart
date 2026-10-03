import 'package:flutter/material.dart';

/// All colours used in the app.
///
/// Two rules:
///  1. Shop colours are not tied to real shops (no "Delhaize red"). The user
///     picks a colour when creating a shop. [presetShopColors] is the list
///     they pick from.
///  2. The app itself is neutral (dark text on light background). Colour
///     only appears as a shop's accent, through AppTheme.forShop().
class AppColors {
  AppColors._();

  // ── Ink ──────────────────────────────────────────────────────────────
  static const Color ink = Color(0xFF1A1A18);

  // ── Backgrounds ──────────────────────────────────────────────────────
  static const Color bgLight = Color(0xFFFAFAF8);
  static const Color bgDark = Color(0xFF151513);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1C);
  static const Color subtleLight = Color(0xFFF5F5F2);
  static const Color subtleDark = Color(0xFF212120);
  static const Color selectedRowLight = Color(0xFFF1F0EB);
  static const Color selectedRowDark = Color(0xFF262624);

  // ── Text ─────────────────────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF1A1A18);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryLight = Color(0x8C1A1A18); // 55%
  static const Color textSecondaryDark = Color(0x8CFFFFFF);
  static const Color textMutedLight = Color(0x661A1A18); // 40%
  static const Color textMutedDark = Color(0x66FFFFFF);
  static const Color textFaintLight = Color(0x521A1A18); // 32%
  static const Color textFaintDark = Color(0x52FFFFFF);

  // ── Lines ────────────────────────────────────────────────────────────
  static const Color borderLight = Color(0x1A000000); // 10%
  static const Color borderDark = Color(0x29FFFFFF); // 16%
  static const Color dividerLight = Color(0x12000000); // 7%
  static const Color dividerDark = Color(0x14FFFFFF); // 8%

  // ── Semantic ─────────────────────────────────────────────────────────
  static const Color destructive = Color(0xFFC0392B);
  static const Color success = Color(0xFF2E9E5B);
  static const Color info = Color(0xFF2456A6);

  // ── Shop swatches (retailer-agnostic) ────────────────────────────────
  static const Color swatchBlue = Color(0xFF2456A6);
  static const Color swatchOrange = Color(0xFFE8791A);
  static const Color swatchRed = Color(0xFFC0392B);
  static const Color swatchGreen = Color(0xFF2E9E5B);
  static const Color swatchPurple = Color(0xFF8E5CD9);
  static const Color swatchGold = Color(0xFFD9A62E);
  static const Color swatchTeal = Color(0xFF1F9AA0);
  static const Color swatchPink = Color(0xFFCB5B9E);

  /// The colours shown in the picker when creating or editing a shop.
  /// The first one is selected by default.
  static const List<Color> presetShopColors = [
    swatchBlue,
    swatchOrange,
    swatchRed,
    swatchGreen,
    swatchPurple,
    swatchGold,
    swatchTeal,
    swatchPink,
  ];

  /// Used when a shop somehow has no colour assigned.
  static const Color shopColorFallback = Color(0xFF8A8A86);

  /// The avatar colour for a household member.
  ///
  /// Based on their user id, so the same person always gets the same colour,
  /// on every phone.
  static Color avatarColorFor(String userId) =>
      presetShopColors[userId.hashCode.abs() % presetShopColors.length];

  /// Blends colour [a] into colour [b]. [t] goes from 0 (all [a]) to 1
  /// (all [b]).
  ///
  /// Why not [Color.lerp]? It blends red, green and blue separately, so
  /// green to orange turns muddy brown halfway. Blending by hue stays
  /// colourful. It also takes the shortest way around the colour wheel.
  /// Used for the theme fade when reduced motion is on (decisions.md #85).
  static Color lerpHsl(Color a, Color b, double t) {
    final ha = HSLColor.fromColor(a);
    final hb = HSLColor.fromColor(b);
    final hueDelta = (hb.hue - ha.hue + 540) % 360 - 180;
    return HSLColor.fromAHSL(
      ha.alpha + (hb.alpha - ha.alpha) * t,
      (ha.hue + hueDelta * t + 360) % 360,
      ha.saturation + (hb.saturation - ha.saturation) * t,
      ha.lightness + (hb.lightness - ha.lightness) * t,
    ).toColor();
  }
}
