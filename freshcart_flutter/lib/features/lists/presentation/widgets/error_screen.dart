import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/ui/failure_state.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// A full-screen error, for when loading failed and there's nothing to show.
///
/// Looks the same as [EmptyState] (through [FailureState]).
///
/// Always has one button to get out, so the user is never stuck.
class ErrorScreen extends StatelessWidget {
  /// Creates the screen for [failure].
  const ErrorScreen({
    required this.failure,
    required this.t,
    required this.onExit,
    super.key,
  });

  /// What went wrong. The kind of failure decides the text (for example
  /// "list deleted" vs. "no access").
  final Failure failure;

  /// Translations for the active locale.
  final Translations t;

  /// What the exit button does.
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      // Fade in, because it replaces a screen the user was looking at.
      body: AnimatedSwitcher(
        duration: AppMotion.durationFor(context, AppMotion.standard),
        child: FailureState(
          key: ValueKey(failure.runtimeType),
          failure: failure,
          t: t,
          action: ElevatedButton(
            onPressed: onExit,
            child: Text(t.errors.backToLists),
          ),
        ),
      ),
    );
  }
}
