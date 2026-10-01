import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/features/settings/application/settings_screen/settings_screen_controller.dart';
import 'package:freshcart_flutter/features/settings/presentation/widgets/sections/about_section.dart';
import 'package:freshcart_flutter/features/settings/presentation/widgets/sections/account_card.dart';
import 'package:freshcart_flutter/features/settings/presentation/widgets/sections/lists_and_shops_section.dart';
import 'package:freshcart_flutter/features/settings/presentation/widgets/sections/preferences_section.dart';
import 'package:freshcart_flutter/features/settings/presentation/widgets/sections/profile_header.dart';

/// Account-level settings, reached from the drawer. Reads
/// [SettingsScreenController]; each section below owns its own writes.
///
/// Only genuinely global things live here (Flow 10): you, your lists as
/// doors into *their* settings, preferences, and signing out. Every gap
/// between groups is the same [AppSpacing.screen].
class SettingsScreen extends ConsumerWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final s = ref.watch(settingsScreenControllerProvider);
    final account = s.profile.dataOrNull;
    // Unknown counts as anonymous: it only decides whether sign-out asks
    // first, and asking once too often is the safe mistake.
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
