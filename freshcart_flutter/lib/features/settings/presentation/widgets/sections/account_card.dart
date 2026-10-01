import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/features/auth/presentation/widgets/upgrade_nudge.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The card nudging an anonymous account to link an email (decisions #56:
/// always visible while anonymous, no dismiss).
///
/// Shown only while anonymous. Once linked, [ProfileHeader]'s email line and
/// its verified tick already say "secured" -- a second card repeating the
/// same address just below it added nothing.
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
                  // The app's themed primary -- the same ink button every
                  // other main action uses, not M3's untinted FilledButton.
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
