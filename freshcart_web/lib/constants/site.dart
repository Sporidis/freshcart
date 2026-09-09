import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Copy and facts for the marketing site.
///
/// Several of these are read from `freshcart_domain` and `freshcart_l10n`
/// rather than retyped, which is the point of sharing those packages: the site
/// cannot claim a six-character join code while the app issues eight, or
/// advertise a language the app does not ship.
abstract final class Site {
  /// The product name.
  static const String name = 'FreshCart';

  /// The one-line pitch, used as the meta description and the hero subtitle.
  static const String tagline =
      'A shared shopping list your whole household actually keeps up to date.';

  /// The longer description used for social cards.
  static const String description =
      'FreshCart is a collaborative shopping list. Add, tick off and annotate '
      'items together in real time, tag them to a shop, and let the app follow '
      'the colour of wherever you are shopping.';

  /// How many characters a join code has. Read from the domain.
  static int get joinCodeLength => JoinCode.length;

  /// The languages the app ships, read from the translations package.
  static List<String> get languages => [
    for (final locale in AppLocale.values) locale.languageCode.toUpperCase(),
  ];

  /// The site's canonical URL, used for Open Graph tags.
  static const String canonicalUrl = 'https://freshcart.example';
}
