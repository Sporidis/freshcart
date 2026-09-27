import 'dart:ui' show PlatformDispatcher;

import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_controller.g.dart';

/// The app's active locale.
///
/// `freshcart_l10n` is generated without Flutter integration so the Jaspr site
/// can share it (`docs/decisions.md` #24), which means there is no
/// `TranslationProvider` doing this for us. Holding the locale in Riverpod is
/// the better fit anyway: it is app state, and every widget that needs strings
/// already has a `ref`.
@Riverpod(keepAlive: true)
class LocaleController extends _$LocaleController {
  @override
  AppLocale build() => _deviceLocaleOrBase();

  /// Switches the app to [locale].
  void select(AppLocale locale) => state = locale;

  /// Matches the device's language against the supported set.
  ///
  /// Falls back to the base locale (`nl`) when the device speaks something
  /// FreshCart does not, which is also slang's own fallback strategy.
  static AppLocale _deviceLocaleOrBase() {
    final deviceCode = PlatformDispatcher.instance.locale.languageCode;
    for (final locale in AppLocale.values) {
      if (locale.languageCode == deviceCode) return locale;
    }
    return AppLocale.nl;
  }
}

/// The translations for the active locale.
///
/// Built through `translationsFor` rather than `buildSync` so the plural
/// resolvers for `nl` and `tl` are applied — see `docs/decisions.md` #25.
@Riverpod(keepAlive: true)
Translations translations(Ref ref) =>
    translationsFor(ref.watch(localeControllerProvider));
