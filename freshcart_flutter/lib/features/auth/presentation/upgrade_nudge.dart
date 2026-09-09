import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/features/auth/data/auth_repository_provider.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Prompts an anonymous user to attach an email to their account.
///
/// The product half of `docs/decisions.md` #6: anonymous-first removes signup
/// friction, but an anonymous session lives only in local storage, so losing
/// the device loses every shared list. The architecture cannot fix that — the
/// mitigation is to ask at the moment the stakes become real, which is when a
/// list is shared or joined. Shown here, on the list detail screen, rather than
/// on first launch where it would just be a signup form with extra steps.
class UpgradeNudge extends ConsumerWidget {
  /// Creates the nudge.
  const UpgradeNudge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final user = ref.watch(currentUserProvider);

    final isAnonymous = switch (user) {
      AsyncValue<Result<AuthUser>>(value: Ok<AuthUser>(:final value)) =>
        value.isAnonymous,
      // Say nothing until the identity is known: a nudge that flickers in and
      // out on every rebuild is worse than no nudge.
      _ => false,
    };
    if (!isAnonymous) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: ListTile(
        leading: Icon(
          Icons.shield_outlined,
          color: theme.colorScheme.onSecondaryContainer,
        ),
        title: Text(t.account.title),
        subtitle: Text(t.account.body),
        trailing: TextButton(
          onPressed: () => _showLinkDialog(context, ref, t),
          child: Text(t.account.action),
        ),
      ),
    );
  }

  Future<void> _showLinkDialog(
    BuildContext context,
    WidgetRef ref,
    Translations t,
  ) => showDialog<void>(
    context: context,
    builder: (context) => const _LinkEmailDialog(),
  );
}

class _LinkEmailDialog extends ConsumerStatefulWidget {
  const _LinkEmailDialog();

  @override
  ConsumerState<_LinkEmailDialog> createState() => _LinkEmailDialogState();
}

class _LinkEmailDialogState extends ConsumerState<_LinkEmailDialog> {
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
