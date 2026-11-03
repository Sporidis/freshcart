import 'package:flutter/material.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// "Invite someone": asks for an invite to share.
///
/// The app's main button style ([ElevatedButton], styled in `AppTheme`):
/// it's the main action wherever it shows. While the invite is being
/// asked for, `InviteCard` shows a spinner in its place, so the button
/// has no loading state of its own.
class OpenInviteButton extends StatelessWidget {
  /// Creates the button.
  const OpenInviteButton({required this.onPressed, required this.t, super.key});

  /// Asks for the invite.
  final VoidCallback onPressed;

  /// Translations for the active locale.
  final Translations t;

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: onPressed,
    child: Text(t.household.inviteSomeone),
  );
}
