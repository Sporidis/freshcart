import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/features/auth/application/profile/profile_controller.dart';
import 'package:freshcart_flutter/features/auth/application/upgrade_nudge/upgrade_nudge_controller.dart';
import 'package:freshcart_flutter/features/auth/application/upgrade_nudge/upgrade_nudge_providers.dart';

/// A banner asking an anonymous user to add an email to their account.
///
/// Why: anonymous accounts only exist on the phone. Lose the phone, lose
/// all your lists. So we ask once it matters, on the list screen, instead
/// of at first launch. See decisions.md #6.
///
/// Once closed, it stays closed (see [UpgradeNudgeController]). The same
/// option is always in Settings.
class UpgradeNudge extends ConsumerWidget {
  /// Creates the nudge.
  const UpgradeNudge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    if (!ref.watch(showUpgradeNudgeProvider)) return const SizedBox.shrink();

    final theme = Theme.of(context);
    // v3's translucent fill, so it reads as a band set into the page in
    // both light and dark mode. Not secondaryContainer: our theme doesn't
    // set that one, so it would come out slightly green.
    return Material(
      color: theme.colorScheme.fill,
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

/// Opens [LinkEmailDialog]. Both [UpgradeNudge] and Settings use this.
Future<void> showLinkEmailDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => const LinkEmailDialog(),
);

/// The form to add an email and password to an anonymous account.
///
/// Public because Settings opens it too.
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
              // Translated here (not when the error is saved), so it
              // updates if the language changes.
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
