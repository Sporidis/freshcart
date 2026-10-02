import 'package:freshcart_l10n/i18n/translations.g.dart';

/// Plural rules for languages slang doesn't know.
///
/// slang only has plural rules for `ar cs de en es fr he it ja pl ru sv uk
/// vi`. Our **nl** (the default language!) and **tl** aren't in that list.
/// Without these rules, slang uses a fallback ("one" only for 1) and logs an
/// error on every plural. That fallback is right for Dutch, but wrong for
/// Tagalog.
const Map<String, PluralResolver> freshCartCardinalResolvers = {
  'nl': _dutchCardinal,
  'tl': _tagalogCardinal,
};

/// Dutch: "one" for exactly 1, "other" for everything else.
String _dutchCardinal(
  num n, {
  String? zero,
  String? one,
  String? two,
  String? few,
  String? many,
  String? other,
}) => n == 1 ? (one ?? other!) : other!;

/// Tagalog: "one", unless the number ends in 4, 6 or 9.
///
/// So 5 and 10 are "one", but 4, 6, 14 and 19 are "other". The fallback
/// gets this wrong for most numbers.
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

/// Gets the [Translations] for [locale], with our plural rules.
///
/// Use this, not `locale.buildSync()`. The rules from
/// [configurePluralResolvers] only apply to the global `LocaleSettings`, so
/// `buildSync()` would quietly use the wrong fallback rules.
Translations translationsFor(AppLocale locale) => locale.buildSync(
  cardinalResolver: freshCartCardinalResolvers[locale.languageCode],
);

/// Registers our plural rules on the global [LocaleSettings] (used by `t`).
///
/// Call once at startup, before showing anything, in both the app and the
/// website.
void configurePluralResolvers() {
  for (final entry in freshCartCardinalResolvers.entries) {
    LocaleSettings.setPluralResolverSync(
      language: entry.key,
      cardinalResolver: entry.value,
    );
  }
}
