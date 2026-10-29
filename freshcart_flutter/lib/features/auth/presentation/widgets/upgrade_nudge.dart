import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/translations_provider.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_fill.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_spacing.dart';
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

/// Opens [_LinkEmailDialog]. Both [UpgradeNudge] and Settings use this.
Future<void> showLinkEmailDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => const _LinkEmailDialog(),
);

/// The form to add an email and password to an anonymous account.
///
/// Public because Settings opens it too.
class _LinkEmailDialog extends ConsumerStatefulWidget {
  const _LinkEmailDialog();

  @override
  ConsumerState<_LinkEmailDialog> createState() => _LinkEmailDialogState();
}

class _LinkEmailDialogState extends ConsumerState<_LinkEmailDialog> {
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
    // Translated here (not when the error is saved), so it updates if the
    // language changes. A password problem goes under the password field,
    // everything else under the email.
    final message = _failure?.toMessage(t);
    final isPasswordIssue = switch (_failure) {
      ValidationFailure(
        issue: ValidationIssue(input: ValidatedInput.password),
      ) =>
        true,
      _ => false,
    };
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
              errorText: isPasswordIssue ? null : message,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _password,
            enabled: !_busy,
            obscureText: true,
            decoration: InputDecoration(
              labelText: t.account.passwordLabel,
              errorText: isPasswordIssue ? message : null,
            ),
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
