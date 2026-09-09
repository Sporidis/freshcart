import 'package:freshcart_l10n/i18n/translations.g.dart';

/// Plural rules for the locales slang does not ship.
///
/// slang has built-in CLDR cardinal resolvers for `ar cs de en es fr he it ja
/// pl ru sv uk vi` only. FreshCart also ships **nl** — its *base* locale — and
/// **tl**, neither of which is covered. Left alone, both fall back to a
/// tolerant default (`one` only when n == 1) and slang logs an error on every
/// plural lookup. That default happens to match Dutch; it does **not** match
/// Tagalog.
const Map<String, PluralResolver> freshCartCardinalResolvers = {
  'nl': _dutchCardinal,
  'tl': _tagalogCardinal,
};

/// Dutch: `one` when the value is exactly 1, `other` otherwise.
String _dutchCardinal(
  num n, {
  String? zero,
  String? one,
  String? two,
  String? few,
  String? many,
  String? other,
}) => n == 1 ? (one ?? other!) : other!;

/// Tagalog: `one` unless the integer part ends in 4, 6 or 9.
///
/// So 5 and 10 are `one` while 4, 6, 14 and 19 are `other` — a rule the
/// tolerant fallback gets wrong for most values.
String _tagalogCardinal(
  num n, {
  String? zero,
  String? one,
  String? two,
  String? few,
  String? many,
  String? other,
}) {
  final lastDigit = n.truncate().remainder(10).abs();
  final isOther = lastDigit == 4 || lastDigit == 6 || lastDigit == 9;
  return isOther ? other! : (one ?? other!);
}

/// Builds the [Translations] for [locale] with FreshCart's resolvers applied.
///
/// Prefer this over `locale.buildSync()` directly: a resolver registered
/// through [configurePluralResolvers] only reaches the `LocaleSettings`
/// singleton, so translations built by hand would silently use the fallback.
Translations translationsFor(AppLocale locale) => locale.buildSync(
  cardinalResolver: freshCartCardinalResolvers[locale.languageCode],
);

/// Registers the resolvers on the [LocaleSettings] singleton that backs the
/// global `t`.
///
/// Call once at startup, before rendering anything, from both the Flutter app
/// and the Jaspr site.
void configurePluralResolvers() {
  for (final entry in freshCartCardinalResolvers.entries) {
    LocaleSettings.setPluralResolverSync(
      language: entry.key,
      cardinalResolver: entry.value,
    );
  }
}
