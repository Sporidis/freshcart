/// FreshCart's translations (slang), used by both the app and the website.
/// Languages: nl (default), en, fr, ru, tl.
///
/// Generated with `flutter_integration: false`, so it's plain Dart (no
/// Flutter) and the website can use it too. Because of that, there's no
/// `TranslationProvider` or `context.t`: the app keeps the language in a
/// Riverpod provider instead (decisions.md #24).
///
/// To regenerate: run `dart run slang` in this package.
library;

export 'i18n/translations.g.dart';
export 'src/plural_resolvers.dart';
