import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// All text styles in the app, copied exactly from the design.
///
/// Sizes: 28/26 titles, 22 sheet titles, 19 card title, 16-17 body,
/// 14-15 secondary, 12-13 captions.
class AppTextStyles {
  AppTextStyles._();

  /// The iOS system font, which the design uses. Replace with a bundled font
  /// before release.
  static const String fontFamily = '.SF Pro Text';

  static const TextStyle largeTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    height: 1.12,
  );
  static const TextStyle screenTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.35,
    height: 1.15,
  );
  static const TextStyle sheetTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  /// Title on cards and the app name on the splash screen.
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );
  static const TextStyle bodyStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle secondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );
  static const TextStyle secondaryStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle labelStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle captionStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  /// Small uppercase section headers, like "LISTS" or "DONE · 3".
  static const TextStyle eyebrow = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.7,
  );

  /// Invite links and codes.
  static const TextStyle code = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle codeLarge = TextStyle(
    fontFamily: 'monospace',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 4,
  );
}
