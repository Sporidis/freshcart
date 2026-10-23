import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';

/// The design's "fill": ink at 5% (white at 7% in dark mode).
///
/// Translucent on purpose, so it shows on any surface: behind a stepper, a
/// close button, a progress track. `surfaceContainer` is an opaque neutral
/// and nearly disappears on a dark sheet or drawer.
extension AppFill on ColorScheme {
  Color get fill => brightness == Brightness.dark
      ? Colors.white.withValues(alpha: .07)
      : AppColors.ink.withValues(alpha: .05);
}
