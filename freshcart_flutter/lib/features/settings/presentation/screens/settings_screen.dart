import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/l10n/translations_provider.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
import 'package:freshcart_flutter/features/settings/application/settings_screen/settings_screen_controller.dart';
import 'package:freshcart_flutter/features/settings/presentation/widgets/sections/about_section.dart';
import 'package:freshcart_flutter/features/settings/presentation/widgets/sections/account_card.dart';
import 'package:freshcart_flutter/features/settings/presentation/widgets/sections/lists_and_shops_section.dart';
import 'package:freshcart_flutter/features/settings/presentation/widgets/sections/preferences_section.dart';
import 'package:freshcart_flutter/features/settings/presentation/widgets/sections/profile_header.dart';

/// The app's main settings screen, opened from the drawer.
///
/// Only app-wide things: your profile, links to each list's own settings,
/// preferences, and sign out. Data comes from [SettingsScreenController].
/// Each section handles its own changes.
class SettingsScreen extends ConsumerWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final s = ref.watch(settingsScreenControllerProvider);
    final account = s.profile.dataOrNull;
    // If we don't know yet, assume anonymous. Worst case, sign-out asks
    // "are you sure?" once when it didn't need to.
    final isAnonymous = account?.isAnonymous ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings.title),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          ProfileHeader(user: s.profile, t: t),
          if (account != null && account.isAnonymous) ...[
            const SizedBox(height: AppSpacing.screen),
            AccountCard(t: t),
          ],
          const SizedBox(height: AppSpacing.screen),
          ListsAndShopsSection(t: t, rows: s.lists),
          const SizedBox(height: AppSpacing.screen),
          PreferencesSection(t: t),
          const SizedBox(height: AppSpacing.screen),
          AboutSection(t: t, isAnonymous: isAnonymous),
        ],
      ),
    );
  }
}
