import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/ui/empty_state.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// A failed load, drawn in place of the content it failed to load.
///
/// The body of [ErrorScreen], without its scaffold, so a screen whose
/// *section* failed (items, shops, all lists) shows the same icon, wording
/// and single action as one that failed whole -- rather than each screen
/// inventing its own centred text and button.
///
/// The failure's *type* picks icon and wording; [action] is the one way
/// forward (Retry, or Back to lists).
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

  /// The single way out. A dead end is how someone ends up force-quitting.
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
      // Never the raw cause: an exception string tells the user nothing and
      // tells an attacker something.
      _ => (
        Icons.error_outline,
        t.errors.unexpectedTitle,
        t.errors.unexpectedBody,
      ),
    };
    return EmptyState(icon: icon, title: title, body: body, action: action);
  }
}

@Preview(group: 'States', name: 'Failure · retry', size: previewPhone)
Widget failureStateRetryPreview() => previewApp(
  Scaffold(
    body: FailureState(
      failure: const Failure.network(),
      t: previewTranslations,
      action: ElevatedButton(onPressed: () {}, child: const Text('Retry')),
    ),
  ),
);
