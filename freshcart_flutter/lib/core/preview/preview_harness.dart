import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Helpers for `@Preview` functions.
///
/// They use the app's real theme, so a preview looks exactly like the app.
/// The same helpers are used in `test/core/preview/previews_test.dart`.
///
/// There's no way to pass provider overrides, because Riverpod 3 doesn't
/// export the `Override` type. If a preview needs one, it makes its own
/// [ProviderScope].

/// The size of a phone screen for previews.
const Size previewPhone = Size(393, 852);

/// Wraps [child] in a [ProviderScope] and the app's real theme.
Widget previewApp(Widget child, {Brightness brightness = Brightness.light}) =>
    ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: brightness == Brightness.dark
            ? AppTheme.dark(AppTheme.brandSeed)
            : AppTheme.light(AppTheme.brandSeed),
        home: child,
      ),
    );

/// [previewApp] for a page that normally sits inside another screen's
/// [Scaffold], like one step of the onboarding wizard.
///
/// Adds the [Scaffold], otherwise a [TextField] inside crashes with
/// "No Material widget found".
Widget previewPage(Widget child, {Brightness brightness = Brightness.light}) =>
    previewApp(
      Scaffold(body: SafeArea(child: child)),
      brightness: brightness,
    );

/// [previewApp] for a single widget (a button, a row), not a whole screen.
///
/// Adds a [Scaffold] and some padding around it, because most Material
/// widgets crash without a [Scaffold] above them.
Widget previewPiece(
  Widget child, {
  Brightness brightness = Brightness.light,
  EdgeInsets padding = const EdgeInsets.all(16),
}) => previewApp(
  Scaffold(
    body: SafeArea(
      child: Padding(padding: padding, child: child),
    ),
  ),
  brightness: brightness,
);

/// English texts for previews.
///
/// The app defaults to Dutch, but previews are for developers, so they're
/// always in English.
Translations get previewTranslations => translationsFor(AppLocale.en);
