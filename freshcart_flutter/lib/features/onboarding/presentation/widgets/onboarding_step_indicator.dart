import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/features/onboarding/application/screen/onboarding_state.dart';

/// The design's dash-pill progress row: the whole 4-step wizard (name, list,
/// shops, invite) rather than the 3-of-3 the mockup's own frames show, since
/// this app's wizard runs one step longer than the screens it draws.
class OnboardingStepIndicator extends ConsumerWidget {
  const OnboardingStepIndicator({required this.step, super.key});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Row(
            children: List.generate(
              OnboardingStep.values.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: step.index == index ? 24 : 6,
                height: 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: step.index == index
                      ? AppColors.ink
                      : theme.colorScheme.outlineVariant,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              t.onboarding.stepOf(
                step: step.index + 1,
                total: OnboardingStep.values.length,
              ),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(
  group: 'Onboarding',
  name: 'Step indicator · all three',
  size: Size(393, 160),
)
Widget onboardingStepIndicatorPreview() => previewPiece(
  const Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 24,
    children: [
      OnboardingStepIndicator(step: OnboardingStep.displayName),
      OnboardingStepIndicator(step: OnboardingStep.createList),
      OnboardingStepIndicator(step: OnboardingStep.addShop),
    ],
  ),
);
