import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'translations_provider.g.dart';

/// All the app's texts in the current language.
///
/// Uses `translationsFor` (not `buildSync`) so our own plural rules for
/// Dutch and Tagalog are included. See decisions.md #25.
@Riverpod(keepAlive: true)
Translations translations(Ref ref) =>
    translationsFor(ref.watch(localeControllerProvider));
