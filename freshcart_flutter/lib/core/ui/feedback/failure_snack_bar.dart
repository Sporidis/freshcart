import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Shows [failure] in a snackbar at the bottom of the screen.
///
/// For errors where the screen itself is still fine (for example, saving
/// failed). Every such error uses this, so they all look the same.
///
/// Stays 4 seconds, or 5 if there's a button. Long enough to read, short
/// enough not to block the add-item bar. The look comes from the theme.
void showFailureSnackBar(
  BuildContext context, {
  required Failure failure,
  required Translations t,
  String? message,
  VoidCallback? onRetry,
}) {
  final messenger = ScaffoldMessenger.of(context)
    // Remove the old snackbar first, so only the newest error is shown.
    ..hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message ?? failure.toMessage(t)),
      duration: Duration(seconds: onRetry == null ? 4 : 5),
      action: onRetry == null
          ? null
          : SnackBarAction(label: t.common.retry, onPressed: onRetry),
    ),
  );
}
