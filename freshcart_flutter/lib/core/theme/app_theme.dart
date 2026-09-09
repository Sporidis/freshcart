import 'package:flutter/material.dart';

/// Builds the app's Material 3 themes from a single seed colour.
///
/// The seed is not a constant: it is the *active shop's* colour, so choosing a
/// shop re-themes the whole app. `ColorScheme.fromSeed` derives a full,
/// contrast-checked scheme from one colour, which is why a shop only has to
/// store one integer.
abstract final class AppTheme {
  /// The seed used when no shop is selected.
  ///
  /// A grocery green, deliberately neutral so the app has an identity of its
  /// own before any shop colour takes over.
  static const Color brandSeed = Color(0xFF2E7D5B);

  /// The light theme derived from [seed].
  static ThemeData light(Color seed) => _build(seed, Brightness.light);

  /// The dark theme derived from [seed].
  static ThemeData dark(Color seed) => _build(seed, Brightness.dark);

  static ThemeData _build(Color seed, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}
