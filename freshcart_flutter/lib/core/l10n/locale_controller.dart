import 'dart:ui' show PlatformDispatcher;

import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_controller.g.dart';

/// The language the app is currently shown in.
///
/// Our translations package doesn't use Flutter (so the website can use it
/// too, see decisions.md #24). That means slang's own Flutter helper isn't
/// available, so we keep the language in Riverpod instead.
@Riverpod(keepAlive: true)
class LocaleController extends _$LocaleController {
  @override
  AppLocale build() => _deviceLocaleOrBase();

  /// Switches the app to [locale].
  void select(AppLocale locale) => state = locale;

  /// Uses the phone's language if we support it, otherwise Dutch.
  static AppLocale _deviceLocaleOrBase() {
    final deviceCode = PlatformDispatcher.instance.locale.languageCode;
    for (final locale in AppLocale.values) {
      if (locale.languageCode == deviceCode) return locale;
    }
    return AppLocale.nl;
  }
}
