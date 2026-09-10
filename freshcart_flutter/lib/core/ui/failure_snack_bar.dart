import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Shows [failure] as the snackbar tier of the design's error rule.
///
/// The one place a "something failed but the app is fine" message is built, so
/// every such failure gets the same shape, duration and retry affordance.
///
/// Four seconds, five with an action: long enough to read, short enough not to
/// sit over the quick-add bar while someone is trying to type. Shape and
/// colour come from `AppTheme`'s snackBarTheme rather than being set here.
void showFailureSnackBar(
  BuildContext context, {
  required Failure failure,
  required Translations t,
  String? message,
  VoidCallback? onRetry,
}) {
  final messenger = ScaffoldMessenger.of(context)
    // One at a time: a queue of stale failures is worse than the newest one.
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
