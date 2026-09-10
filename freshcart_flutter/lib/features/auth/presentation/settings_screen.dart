import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/features/auth/data/auth_repository_provider.dart';
import 'package:freshcart_flutter/features/auth/presentation/upgrade_nudge.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Account-level settings, reached from the drawer.
///
/// Deliberately small: the one thing here today is the account's security
/// state, which used to live only in [UpgradeNudge] on the list screen.
/// Dismissing that banner had to leave "link an email" reachable somewhere,
/// and this is that somewhere — a natural, extensible home for whatever
/// app-wide (not list-scoped) preferences come later, not a placeholder
/// screen invented just to hold one row.
class SettingsScreen extends ConsumerWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.settings.title),
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screen),
        children: [
          switch (user) {
            AsyncValue<Result<AuthUser>>(value: Ok<AuthUser>(:final value)) =>
              _AccountCard(user: value, t: t),
            _ => const SizedBox.shrink(),
          },
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user, required this.t});

  final AuthUser user;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linked = !user.isAnonymous;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              linked ? Icons.verified_user_outlined : Icons.shield_outlined,
              color: linked ? AppColors.success : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    linked ? t.account.linked : t.account.title,
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    // A linked account already names the address it is
                    // secured by; email is null only for the (unexpected)
                    // case of a linked account with no email on record.
                    linked ? (user.email ?? '') : t.account.body,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (!linked) ...[
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => showLinkEmailDialog(context),
                      child: Text(t.account.action),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
