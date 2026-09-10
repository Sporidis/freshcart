import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/features/auth/application/upgrade_nudge_dismissed.dart';
import 'package:freshcart_flutter/features/auth/data/auth_repository_provider.dart';

/// Prompts an anonymous user to attach an email to their account.
///
/// The product half of `docs/decisions.md` #6: anonymous-first removes signup
/// friction, but an anonymous session lives only in local storage, so losing
/// the device loses every shared list. The architecture cannot fix that — the
/// mitigation is to ask at the moment the stakes become real, which is when a
/// list is shared or joined. Shown here, on the list detail screen, rather than
/// on first launch where it would just be a signup form with extra steps.
///
/// Dismissible, and permanently so (see [UpgradeNudgeDismissed]) — the same
/// action stays one tap away from Settings for whenever it is actually
/// wanted, so nothing is lost by not repeating it on every list opened.
class UpgradeNudge extends ConsumerWidget {
  /// Creates the nudge.
  const UpgradeNudge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final user = ref.watch(currentUserProvider);
    final dismissed = ref.watch(upgradeNudgeDismissedProvider);

    final isAnonymous = switch (user) {
      AsyncValue<Result<AuthUser>>(value: Ok<AuthUser>(:final value)) =>
        value.isAnonymous,
      // Say nothing until the identity is known: a nudge that flickers in and
      // out on every rebuild is worse than no nudge.
      _ => false,
    };
    // Same discipline for the dismissed flag: assume dismissed while it is
    // still loading from disk, rather than flash the banner for one frame
    // on every cold start before quietly taking it away again.
    final isDismissed = dismissed.hasValue ? dismissed.requireValue : true;
    if (!isAnonymous || isDismissed) return const SizedBox.shrink();

    final theme = Theme.of(context);
    // The neutral surfaceContainerHighest, not secondaryContainer: the same
    // "chrome is neutral ink-on-paper" rule AppTheme fixes surfaceContainer*
    // for applies here too -- a notice banner is chrome, not a coloured
    // accent, and secondaryContainer carries the identical un-overridden-M3
    // risk that made the add-item bar a stray olive-green.
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: ListTile(
        leading: Icon(Icons.shield_outlined, color: theme.colorScheme.onSurface),
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
                  ref.read(upgradeNudgeDismissedProvider.notifier).dismiss(),
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
  String? _error;
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
      _error = null;
    });
    final result = await ref
        .read(authRepositoryProvider)
        .linkEmail(email: _email.text.trim(), password: _password.text);
    if (!mounted) return;

    switch (result) {
      case Ok<AuthUser>():
        ref.invalidate(currentUserProvider);
        Navigator.of(context).pop();
      case Err<AuthUser>(:final failure):
        setState(() {
          _busy = false;
          _error = failure.toMessage(ref.read(translationsProvider));
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
              errorText: _error,
            ),
          ),
          const SizedBox(height: 8),
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
