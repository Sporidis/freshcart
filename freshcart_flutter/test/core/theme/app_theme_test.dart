import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';

/// A component role and the "on" role that has to actually contrast with it
/// — text/icons drawn in [on] on top of a [role]-coloured background must
/// never be the same colour as that background, or they're invisible.
///
/// Regression coverage for exactly that: dark mode, no active shop (the
/// app's default state on most screens) used to set primary/secondary/
/// tertiary and their "on" counterparts to the *same* white, because a
/// local "whichever text colour suits this brightness" variable was reused
/// somewhere that needed the fixed ink colour instead. Every
/// `FilledButton`, `FloatingActionButton`, and checkbox check-mark reading
/// those roles rendered with invisible content — this is what "buttons not
/// being readable" in dark mode actually was.
void main() {
  group('AppTheme neutral (no active shop)', () {
    for (final brightness in Brightness.values) {
      test('$brightness: primary/onPrimary contrast', () {
        final theme = brightness == Brightness.dark
            ? AppTheme.dark(AppTheme.brandSeed)
            : AppTheme.light(AppTheme.brandSeed);
        expect(
          theme.colorScheme.primary,
          isNot(equals(theme.colorScheme.onPrimary)),
          reason:
              'a FilledButton/FAB reading these would render invisible text',
        );
      });

      test('$brightness: secondary/onSecondary contrast', () {
        final theme = brightness == Brightness.dark
            ? AppTheme.dark(AppTheme.brandSeed)
            : AppTheme.light(AppTheme.brandSeed);
        expect(
          theme.colorScheme.secondary,
          isNot(equals(theme.colorScheme.onSecondary)),
        );
      });

      test('$brightness: tertiary/onTertiary contrast', () {
        final theme = brightness == Brightness.dark
            ? AppTheme.dark(AppTheme.brandSeed)
            : AppTheme.light(AppTheme.brandSeed);
        expect(
          theme.colorScheme.tertiary,
          isNot(equals(theme.colorScheme.onTertiary)),
        );
      });
    }
  });

  group('AppTheme.forShop', () {
    // A spread of real preset colours, not just one -- the whole point of
    // AppTheme.forShop is that it has to hold up for whatever colour a shop
    // was actually given, not just a colour that happens to work.
    for (final shopColor in [
      Colors.orange,
      Colors.teal,
      Colors.purple,
      Colors.yellow,
      Colors.black,
      Colors.white,
    ]) {
      for (final brightness in Brightness.values) {
        test('$shopColor in $brightness: primary/onPrimary contrast', () {
          final theme = AppTheme.forShop(shopColor, brightness);
          expect(
            theme.colorScheme.primary,
            isNot(equals(theme.colorScheme.onPrimary)),
          );
        });
      }
    }

    test('a null shop colour falls back without throwing', () {
      expect(
        () => AppTheme.forShop(null, Brightness.dark),
        returnsNormally,
      );
    });
  });
}
