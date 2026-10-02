import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/features/auth/presentation/widgets/upgrade_nudge.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The card in Settings asking an anonymous user to add an email.
///
/// Always shown while anonymous, and can't be closed (decisions.md #56).
/// Hidden once an email is linked: [ProfileHeader] shows the email then.
class AccountCard extends StatelessWidget {
  const AccountCard({required this.t, super.key});

  final Translations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screen),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined, color: theme.colorScheme.onSurface),
            const SizedBox(width: AppSpacing.gap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.account.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.gapSmall),
                  Text(t.account.body, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.gap),
                  // Our themed main button, same as everywhere else.
                  ElevatedButton(
                    onPressed: () => showLinkEmailDialog(context),
                    child: Text(t.account.action),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
