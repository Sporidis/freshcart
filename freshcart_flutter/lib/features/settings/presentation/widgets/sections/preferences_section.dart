import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/haptics/haptics_controller.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/preferences/appearance_controller.dart';
import 'package:freshcart_flutter/core/theme/preferences/large_text_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_dropdown_option.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_option.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_status_option.dart';
import 'package:freshcart_flutter/core/ui/settings/setting_toggle_option.dart';
import 'package:freshcart_flutter/core/ui/settings/settings_section.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// The "Preferences" section in Settings: theme, language, notifications,
/// and settings that are only saved on this phone.
class PreferencesSection extends ConsumerWidget {
  const PreferencesSection({required this.t, super.key});

  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance =
        ref.watch(appearanceControllerProvider).value ?? Appearance.system;
    final largeText = ref.watch(largeTextControllerProvider).value ?? false;
    final haptics = ref.watch(hapticsControllerProvider).value ?? true;
    return SettingsSection(
      label: t.settings.preferences,
      children: [
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
          description: t.settings.largerListTextBody,
          value: largeText,
          onChanged: (value) =>
              ref.read(largeTextControllerProvider.notifier).select(value),
        ),
        SettingStatusOption(
          title: t.settings.reduceMotion,
          description: t.settings.reduceMotionBody,
          status: AppMotion.reduced(context) ? t.settings.on : t.settings.off,
        ),
        SettingOption(
          title: t.settings.notifications,
          onTap: () => context.push(Routes.notifications),
        ),
        // No "Keep checked items" here: that's a setting per list now
        // ("Clear checked after shopping" in list settings).
        // See decisions.md #69 and #79.
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
