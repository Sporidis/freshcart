import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/theme/appearance_provider.dart';
import 'package:freshcart_flutter/features/auth/presentation/widgets/setting_dropdown_option.dart';
import 'package:freshcart_flutter/features/auth/presentation/widgets/setting_toggle_option.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The Settings screen's "Preferences" group: appearance, language,
/// notifications, and the local-only toggles.
class PreferencesSection extends ConsumerWidget {
  const PreferencesSection({required this.t, super.key});

  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.settings.preferences,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SettingDropdownOption<Appearance>(
          title: t.settings.appearance,
          value: appearance,
          options: {
            Appearance.system: t.settings.currentAppearance(
              mode: t.settings.appearanceSystem,
            ),
            Appearance.light: t.settings.currentAppearance(
              mode: t.settings.appearanceLight,
            ),
            Appearance.dark: t.settings.currentAppearance(
              mode: t.settings.appearanceDark,
            ),
          },
          onChanged: (value) =>
              ref.read(appearanceControllerProvider.notifier).select(value),
        ),
        SettingDropdownOption<AppLocale>(
          title: t.settings.language,
          value: ref.watch(activeLocaleProvider),
          options: {
            AppLocale.nl: 'Nederlands',
            AppLocale.en: 'English',
            AppLocale.fr: 'Français',
            AppLocale.ru: 'Русский',
            AppLocale.tl: 'Tagalog',
          },
          onChanged: (value) =>
              ref.read(activeLocaleProvider.notifier).select(value),
        ),
        // Notifications: not a row here yet. The design wants four push
        // toggles plus per-list mute, one of which needs a scheduled local
        // notification and its own new dependency — real work, not styling,
        // so it stays off the screen until it exists rather than pointing
        // at nothing. See docs/design-gap-plan.md §8.
        //
        // "Keep checked items" (global): dropped, not just left dead. Decision
        // #64/#69 replaced it with a per-list "Clear checked after
        // shopping" toggle, which itself isn't built yet (needs a real
        // domain decision on what "after shopping" means) — see decision
        // #69. A global toggle for a preference that's becoming per-list
        // would be the wrong shape to ship even temporarily.
        SettingToggleOption(
          title: t.settings.haptics,
          value: true,
          onChanged: (_) {},
        ),
      ],
    );
  }
}
