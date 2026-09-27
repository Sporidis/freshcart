import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/haptics/haptics_controller.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/theme/appearance_controller.dart';
import 'package:freshcart_flutter/core/theme/large_text_controller.dart';
import 'package:freshcart_flutter/features/auth/presentation/widgets/setting_dropdown_option.dart';
import 'package:freshcart_flutter/features/auth/presentation/widgets/setting_status_option.dart';
import 'package:freshcart_flutter/features/auth/presentation/widgets/setting_toggle_option.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// The Settings screen's "Preferences" group: appearance, language,
/// notifications, and the local-only toggles.
class PreferencesSection extends ConsumerWidget {
  const PreferencesSection({required this.t, super.key});

  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance =
        ref.watch(appearanceControllerProvider).value ?? Appearance.system;
    final largeText = ref.watch(largeTextControllerProvider).value ?? false;
    final haptics = ref.watch(hapticsControllerProvider).value ?? true;
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
          value: ref.watch(localeControllerProvider),
          options: {
            AppLocale.nl: 'Nederlands',
            AppLocale.en: 'English',
            AppLocale.fr: 'Français',
            AppLocale.ru: 'Русский',
            AppLocale.tl: 'Tagalog',
          },
          onChanged: (value) =>
              ref.read(localeControllerProvider.notifier).select(value),
        ),
        SettingToggleOption(
          title: t.settings.largerListText,
          value: largeText,
          onChanged: (value) =>
              ref.read(largeTextControllerProvider.notifier).select(value),
        ),
        SettingStatusOption(
          title: t.settings.reduceMotion,
          status: AppMotion.reduced(context) ? t.settings.on : t.settings.off,
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          title: Text(t.settings.notifications),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(Routes.notifications),
        ),
        // "Keep checked items" (global): dropped, not just left dead. Decision
        // #64/#69 replaced it with a per-list "Clear checked after
        // shopping" toggle, which itself isn't built yet (needs a real
        // domain decision on what "after shopping" means) — see decision
        // #69. A global toggle for a preference that's becoming per-list
        // would be the wrong shape to ship even temporarily.
        SettingToggleOption(
          title: t.settings.haptics,
          value: haptics,
          onChanged: (value) =>
              ref.read(hapticsControllerProvider.notifier).select(value),
        ),
      ],
    );
  }
}
