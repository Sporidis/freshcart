import 'package:flutter/material.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// "Invite someone": asks for an invite to share. Shows a spinner instead of
/// the label while asking, and can't be tapped again until it's done.
class OpenInviteButton extends StatelessWidget {
  /// Creates the button.
  const OpenInviteButton({
    required this.loading,
    required this.onPressed,
    required this.t,
    super.key,
  });

  /// Whether the invite is being asked for right now.
  final bool loading;

  /// Asks for the invite.
  final VoidCallback onPressed;

  /// Translations for the active locale.
  final Translations t;

  @override
  Widget build(BuildContext context) => FilledButton.tonal(
    onPressed: loading ? null : onPressed,
    child: loading
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(t.household.inviteSomeone),
  );
}
