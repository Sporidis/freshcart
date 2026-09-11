import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/features/auth/data/auth_repository_provider.dart';
import 'package:freshcart_flutter/features/auth/presentation/settings_widgets.dart';
import 'package:freshcart_flutter/features/lists/application/lists_controller.dart';

/// Account-level settings, reached from the drawer.
class SettingsScreen extends ConsumerWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final user = ref.watch(currentUserProvider);
    final firstList = switch (ref.watch(listsControllerProvider)) {
      AsyncOutcome<List<ShoppingList>>(
        value: Ok<List<ShoppingList>>(:final value),
      )
          when value.isNotEmpty =>
        value.first,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings.title),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          ProfileHeader(user: user, t: t),
          switch (user) {
            AsyncValue<Result<AuthUser>>(value: Ok<AuthUser>(:final value)) =>
              AccountCard(user: value, t: t),
            _ => const SizedBox.shrink(),
          },
          const SizedBox(height: 12),
          ListsAndShopsSection(t: t, firstList: firstList),
          const SizedBox(height: 12),
          PreferencesSection(t: t),
          const SizedBox(height: 12),
          AboutSection(t: t),
        ],
      ),
    );
  }
}
