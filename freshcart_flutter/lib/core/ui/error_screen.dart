import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/ui/empty_state.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The screen tier: shown when a failure leaves nothing to render.
///
/// Reuses [EmptyState]'s stack rather than inventing a second centred layout —
/// "the list is gone" and "the list is empty" are the same shape of message,
/// and the design draws them the same way.
///
/// Always offers exactly one way out. A dead end here is how someone ends up
/// force-quitting the app.
class ErrorScreen extends StatelessWidget {
  /// Creates the screen for [failure].
  const ErrorScreen({
    required this.failure,
    required this.t,
    required this.onExit,
    super.key,
  });

  /// What went wrong. Its *type* picks the wording, since the user needs to
  /// know whether the list is gone or they simply cannot see it any more.
  final Failure failure;

  /// Translations for the active locale.
  final Translations t;

  /// The single way out.
  final VoidCallback onExit;

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

    return Scaffold(
      appBar: AppBar(),
      // Cross-fades in rather than popping: this replaces a screen someone was
      // already reading.
      body: AnimatedSwitcher(
        duration: AppMotion.durationFor(context, AppMotion.standard),
        child: EmptyState(
          key: ValueKey(title),
          icon: icon,
          title: title,
          body: body,
          action: ElevatedButton(
            onPressed: onExit,
            child: Text(t.errors.backToLists),
          ),
        ),
      ),
    );
  }
}
