import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/ui/failure_state.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The screen tier: shown when a failure leaves nothing to render.
///
/// Reuses [EmptyState]'s stack (through [FailureState]) rather than inventing
/// a second centred layout — "the list is gone" and "the list is empty" are
/// the same shape of message, and the design draws them the same way.
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
    return Scaffold(
      appBar: AppBar(),
      // Cross-fades in rather than popping: this replaces a screen someone was
      // already reading.
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

@Preview(group: 'States', name: 'Error · list deleted', size: previewPhone)
Widget errorScreenDeletedPreview() => previewApp(
  ErrorScreen(
    failure: const Failure.notFound(),
    t: previewTranslations,
    onExit: () {},
  ),
);

@Preview(group: 'States', name: 'Error · no access', size: previewPhone)
Widget errorScreenNoAccessPreview() => previewApp(
  ErrorScreen(
    failure: const Failure.unauthorized(),
    t: previewTranslations,
    onExit: () {},
  ),
);

@Preview(group: 'States', name: 'Error · unexpected', size: previewPhone)
Widget errorScreenUnexpectedPreview() => previewApp(
  ErrorScreen(
    failure: const Failure.unexpected(),
    t: previewTranslations,
    onExit: () {},
  ),
);
