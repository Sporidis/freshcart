import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/features/auth/application/profile/profile_controller.dart';
import 'package:freshcart_flutter/features/auth/application/upgrade_nudge/upgrade_nudge_controller.dart';
import 'package:freshcart_flutter/features/auth/application/upgrade_nudge/upgrade_nudge_providers.dart';

/// Prompts an anonymous user to attach an email to their account.
///
/// The product half of `docs/decisions.md` #6: anonymous-first removes signup
/// friction, but an anonymous session lives only in local storage, so losing
/// the device loses every shared list. The architecture cannot fix that — the
/// mitigation is to ask at the moment the stakes become real, which is when a
/// list is shared or joined. Shown here, on the list detail screen, rather than
/// on first launch where it would just be a signup form with extra steps.
///
/// Dismissible, and permanently so (see [UpgradeNudgeController]) — the same
/// action stays one tap away from Settings for whenever it is actually
/// wanted, so nothing is lost by not repeating it on every list opened.
class UpgradeNudge extends ConsumerWidget {
  /// Creates the nudge.
  const UpgradeNudge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    if (!ref.watch(showUpgradeNudgeProvider)) return const SizedBox.shrink();

    final theme = Theme.of(context);
    // The neutral surfaceContainerHighest, not secondaryContainer: the same
    // "chrome is neutral ink-on-paper" rule AppTheme fixes surfaceContainer*
    // for applies here too -- a notice banner is chrome, not a coloured
    // accent, and secondaryContainer carries the identical un-overridden-M3
    // risk that made the add-item bar a stray olive-green.
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: ListTile(
        leading: Icon(
          Icons.shield_outlined,
          color: theme.colorScheme.onSurface,
        ),
        title: Text(t.account.title),
        subtitle: Text(t.account.body),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => showLinkEmailDialog(context),
              child: Text(t.account.action),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: t.common.dismiss,
              color: theme.colorScheme.onSurfaceVariant,
              onPressed: () =>
                  ref.read(upgradeNudgeControllerProvider.notifier).dismiss(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens [LinkEmailDialog]. The one place this gets shown from, so
/// [UpgradeNudge] and the settings screen cannot drift into two different
/// dialogs for the same action.
Future<void> showLinkEmailDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => const LinkEmailDialog(),
);

/// The form that attaches an email/password to an anonymous account.
///
/// Public because both [UpgradeNudge] and the settings screen open it —
/// dismissing the nudge must not also remove the only way to reach this.
class LinkEmailDialog extends ConsumerStatefulWidget {
  /// Creates the dialog.
  const LinkEmailDialog({super.key});

  @override
  ConsumerState<LinkEmailDialog> createState() => LinkEmailDialogState();
}

class LinkEmailDialogState extends ConsumerState<LinkEmailDialog> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  Failure? _failure;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _failure = null;
    });
    final failure = await ref
        .read(profileControllerProvider.notifier)
        .linkEmail(email: _email.text.trim(), password: _password.text);
    if (!mounted) return;

    if (failure == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _failure = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    return AlertDialog(
      title: Text(t.account.action),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _email,
            autofocus: true,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: t.account.emailLabel,
              // Translated here, not when stored: a language switch while
              // the dialog is open re-renders the error in the new locale.
              errorText: _failure?.toMessage(t),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _password,
            enabled: !_busy,
            obscureText: true,
            decoration: InputDecoration(labelText: t.account.passwordLabel),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: Text(t.common.save),
        ),
      ],
    );
  }
}
