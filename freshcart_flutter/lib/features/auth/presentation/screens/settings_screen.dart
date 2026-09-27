import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/features/auth/application/controllers/profile_controller.dart';
import 'package:freshcart_flutter/features/auth/presentation/widgets/sections/about_section.dart';
import 'package:freshcart_flutter/features/auth/presentation/widgets/sections/account_card.dart';
import 'package:freshcart_flutter/features/auth/presentation/widgets/sections/lists_and_shops_section.dart';
import 'package:freshcart_flutter/features/auth/presentation/widgets/sections/preferences_section.dart';
import 'package:freshcart_flutter/features/auth/presentation/widgets/sections/profile_header.dart';
import 'package:freshcart_flutter/features/lists/application/controllers/lists_controller.dart';

/// Account-level settings, reached from the drawer.
class SettingsScreen extends ConsumerWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final user = ref.watch(profileControllerProvider);
    final account = user.dataOrNull;
    final lists = ref.watch(listsControllerProvider).dataOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings.title),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          ProfileHeader(user: user, t: t),
          account == null
              ? const SizedBox.shrink()
              : AccountCard(user: account, t: t),
          const SizedBox(height: 12),
          ListsAndShopsSection(t: t, allUserLists: lists),
          const SizedBox(height: 12),
          PreferencesSection(t: t),
          const SizedBox(height: 12),
          AboutSection(t: t),
        ],
      ),
    );
  }
}
