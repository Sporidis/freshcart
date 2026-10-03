import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_state.dart';

/// Where you are in onboarding (design v3): one dot per step, centred in
/// the top bar. The current dot widens to 22px; dots up to and including
/// it are ink, the ones still to come are faint.
///
/// The invite step gets a dot too. It's optional, but v3 says so with the
/// Skip button next to it rather than by leaving it uncounted.
///
/// Screen readers hear "Step 2 of 4" instead of four shapes.
class OnboardingStepIndicator extends ConsumerWidget {
  /// Creates the dots for [step].
  const OnboardingStepIndicator({required this.step, super.key});

  final OnboardingStep step;

  static const double _dot = 6;
  static const double _current = 22;
  static const double _gap = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final ink = Theme.of(context).colorScheme.onSurface;
    const steps = OnboardingStep.values;
    final position = step.index;
    final duration = AppMotion.durationFor(context, AppMotion.onboardingStep);

    return Semantics(
      label: t.onboarding.stepOf(step: position + 1, total: steps.length),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0) const SizedBox(width: _gap),
            AnimatedContainer(
              duration: duration,
              curve: AppMotion.emphasized,
              width: i == position ? _current : _dot,
              height: _dot,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_dot / 2),
                color: i <= position ? ink : ink.withValues(alpha: .28),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

@Preview(
  group: 'Onboarding',
  name: 'Step dots · all four',
  size: Size(393, 160),
)
Widget onboardingStepIndicatorPreview() => previewPiece(
  Column(
    mainAxisSize: MainAxisSize.min,
    spacing: 24,
    children: [
      for (final step in OnboardingStep.values)
        OnboardingStepIndicator(step: step),
    ],
  ),
);
