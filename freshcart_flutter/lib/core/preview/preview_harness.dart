import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Shared scaffolding for `@Preview` functions.
///
/// Previews earn their keep only if they cannot drift from the app, so these
/// helpers hand the widget the *real* theme rather than a preview-only
/// palette: a preview that styles itself can never catch a theme regression,
/// which is most of what these exist for.
///
/// Each helper returns the finished widget rather than being handed to
/// `@Preview(wrapper:)`, so a test can pump exactly what the previewer
/// renders — see `test/core/preview/previews_test.dart`.
///
/// Note there is no `overrides` parameter: Riverpod 3 does not export the
/// `Override` type, so it cannot be named in a signature. A preview whose
/// widget reads a provider that would reach the network builds its own
/// [ProviderScope] instead. Most do not — `OnboardingController.build()`, for
/// one, is pure.

/// A phone-sized preview canvas, matching the design's 390x844 artboards.
const Size previewPhone = Size(393, 852);

/// Wraps [child] in the Riverpod scope and the app's real theme.
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

/// [previewApp] for page-sized content that expects to sit inside a screen's
/// [Scaffold] — a wizard step, say, which the shell normally supplies one for.
///
/// Without this the widget renders but any [TextField] in it throws "No
/// Material widget found": [MaterialApp.home] provides theming and
/// directionality, not a [Material] surface.
Widget previewPage(Widget child, {Brightness brightness = Brightness.light}) =>
    previewApp(
      Scaffold(body: SafeArea(child: child)),
      brightness: brightness,
    );

/// [previewApp] for a widget that is not itself a screen.
///
/// Supplies the [Scaffold] a bare widget would otherwise lack — most of
/// Material needs one above it, and a preview that red-screens on a missing
/// ancestor teaches nothing about the widget it was meant to show.
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

/// English strings for previews of widgets that take a [Translations].
///
/// `nl` is the app's default locale, but previews are read by whoever is
/// building the screen, so they are pinned to English deliberately.
Translations get previewTranslations => translationsFor(AppLocale.en);
