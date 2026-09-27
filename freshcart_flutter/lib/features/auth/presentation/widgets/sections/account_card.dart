import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/features/auth/presentation/upgrade_nudge.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The card nudging an anonymous account to link an email, or confirming one
/// already is.
class AccountCard extends StatelessWidget {
  const AccountCard({required this.user, required this.t, super.key});

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
