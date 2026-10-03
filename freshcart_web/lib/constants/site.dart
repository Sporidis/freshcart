import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Texts and facts for the website.
///
/// Some come straight from `freshcart_domain` and `freshcart_l10n` (not
/// copied), so the website can never say something different from the app
/// (like a wrong join code length, or a language the app doesn't have).
abstract final class Site {
  /// The product name.
  static const String name = 'FreshCart';

  /// The one-line pitch (meta description and the subtitle at the top).
  static const String tagline =
      'A shared shopping list your whole household actually keeps up to date.';

  /// The longer description, for link previews on social media.
  static const String description =
      'FreshCart is a collaborative shopping list. Add, tick off and annotate '
      'items together in real time, tag them to a shop, and let the app follow '
      'the colour of wherever you are shopping.';

  /// How many characters a join code has (from the domain).
  static int get joinCodeLength => JoinCode.length;

  /// The app's languages (from the translations package).
  static List<String> get languages => [
    for (final locale in AppLocale.values) locale.languageCode.toUpperCase(),
  ];

  /// The website's main URL, for Open Graph (link preview) tags.
  static const String canonicalUrl = 'https://freshcart.example';
}
