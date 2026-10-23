import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/ui/empty_state.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// An error message shown where content failed to load.
///
/// Same as [ErrorScreen], but without the [Scaffold], so it can be used for
/// one part of a screen (like just the items).
///
/// The kind of failure picks the icon and text. [action] is the button
/// (Retry, or Back to lists).
class FailureState extends StatelessWidget {
  /// Creates the state for [failure].
  const FailureState({
    required this.failure,
    required this.t,
    required this.action,
    super.key,
  });

  final Failure failure;
  final Translations t;

  /// The button that gets the user out, so they're never stuck.
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final (icon, title, body) = switch (failure) {
      NotFoundFailure() => (
        Icons.highlight_off,
        t.errors.listDeletedTitle,
        t.errors.listDeletedBody,
      ),
      UnauthorizedFailure() => (
        Icons.lock_outline,
        t.errors.noAccessTitle,
        t.errors.noAccessBody,
      ),
      NetworkFailure() => (
        Icons.wifi_off,
        t.errors.unexpectedTitle,
        t.errors.network,
      ),
      // Never show the raw error text. It doesn't help the user and could
      // leak technical details.
      _ => (
        Icons.error_outline,
        t.errors.unexpectedTitle,
        t.errors.unexpectedBody,
      ),
    };
    return EmptyState(icon: icon, title: title, body: body, action: action);
  }
}
