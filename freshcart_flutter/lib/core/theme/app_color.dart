import 'package:flutter/material.dart';

/// Basket colour palette.
///
/// Two rules that shape this file:
///  1. Shop colours are NOT hardcoded to retailers. Every shop's colour is
///     chosen by the user at shop-creation time; [presetShopColors] is just
///     the curated set the picker offers.
///  2. The app's own chrome is neutral ink-on-paper. Colour enters only as
///     the active shop's accent, injected through AppTheme.forShop().
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
  static const Color undoAccent = Color(0xFFF0A868); // on dark snackbars

  // ── Shop swatches (retailer-agnostic) ────────────────────────────────
  static const Color swatchBlue = Color(0xFF2456A6);
  static const Color swatchOrange = Color(0xFFE8791A);
  static const Color swatchRed = Color(0xFFC0392B);
  static const Color swatchGreen = Color(0xFF2E9E5B);
  static const Color swatchPurple = Color(0xFF8E5CD9);
  static const Color swatchGold = Color(0xFFD9A62E);
  static const Color swatchTeal = Color(0xFF1F9AA0);
  static const Color swatchPink = Color(0xFFCB5B9E);

  /// The colour picker offered when a user creates or edits a shop.
  /// First entry is the default suggestion.
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

  /// Deterministic avatar colour for a household member, so the same person
  /// is always the same colour on every device.
  static Color avatarColorFor(String userId) =>
      presetShopColors[userId.hashCode.abs() % presetShopColors.length];

  /// Interpolates [a] to [b] by hue/saturation/lightness, taking the short
  /// way around the hue wheel.
  ///
  /// A plain RGB blend (what [Color.lerp] and [ThemeData.lerp] do) between
  /// two saturated, differently-hued colours passes through a desaturated
  /// grey-brown at the midpoint -- e.g. green to orange dips through mud,
  /// because R/G/B are interpolated independently with no notion of "hue".
  /// [HSLColor.lerp] fixes the desaturation problem but still walks hue the
  /// long way when the two hues are more than 180° apart; this takes the
  /// shorter arc instead. Used for the reduced-motion theme crossfade --
  /// see decisions #85.
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
