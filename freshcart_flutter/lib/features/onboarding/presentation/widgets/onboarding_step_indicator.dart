import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_state.dart';

/// The step indicator: a small dash per step (the current one is longer),
/// then "Step n of 3".
///
/// Only counts the first 3 steps ([numberedSteps]). The invite step is
/// optional, so calling it "Step 4 of 4" would make it look required. On
/// that step the indicator is hidden.
class OnboardingStepIndicator extends ConsumerStatefulWidget {
  /// Creates the rail for [step].
  const OnboardingStepIndicator({required this.step, super.key});

  final OnboardingStep step;

  /// The steps that are counted, in order.
  static const numberedSteps = [
    OnboardingStep.displayName,
    OnboardingStep.createList,
    OnboardingStep.addShop,
  ];

  @override
  ConsumerState<OnboardingStepIndicator> createState() =>
      _OnboardingStepIndicatorState();
}

class _OnboardingStepIndicatorState
    extends ConsumerState<OnboardingStepIndicator> {
  static const double _dashWidth = 6;
  static const double _activeWidth = 22;
  static const double _height = 4;

  /// How far the "Step n of 3" text slides when it changes (as a fraction
  /// of its height).
  static const double _counterTravel = 0.6;

  /// +1 after going forward, -1 after going back. The text slides up when
  /// going forward, and down when going back.
  int _direction = 1;

  @override
  void didUpdateWidget(OnboardingStepIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.step != oldWidget.step) {
      _direction = widget.step.index > oldWidget.step.index ? 1 : -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);
    final position = OnboardingStepIndicator.numberedSteps.indexOf(
      widget.step,
    );
    final total = OnboardingStepIndicator.numberedSteps.length;
    final pillDuration = AppMotion.durationFor(context, AppMotion.bouncy);
    final pillCurve = AppMotion.curveFor(context, AppMotion.pop);
    final direction = _direction;

    return AnimatedSize(
      duration: AppMotion.durationFor(context, AppMotion.standard),
      curve: AppMotion.enter,
      alignment: Alignment.topLeft,
      child: position == -1
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screen,
                AppSpacing.gap,
                AppSpacing.screen,
                0,
              ),
              child: Row(
                children: [
                  for (var i = 0; i < total; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.gapSmall),
                    AnimatedContainer(
                      duration: pillDuration,
                      curve: pillCurve,
                      width: i == position ? _activeWidth : _dashWidth,
                      height: _height,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        color: i == position
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ],
                  const SizedBox(width: AppSpacing.gap),
                  // "Step 1 of 3": slides and fades when the step changes.
                  // The key makes Flutter treat each step's text as new.
                  ClipRect(
                    child: AnimatedSwitcher(
                      duration: pillDuration,
                      switchInCurve: AppMotion.enter,
                      switchOutCurve: AppMotion.exit,
                      layoutBuilder: (current, previous) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [...previous, ?current],
                      ),
                      transitionBuilder: (child, animation) {
                        final incoming = child.key == ValueKey(position);
                        final from = Offset(
                          0,
                          (incoming ? _counterTravel : -_counterTravel) *
                              direction,
                        );
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween(
                              begin: from,
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        t.onboarding.stepOf(step: position + 1, total: total),
                        key: ValueKey(position),
                        style: AppTextStyles.captionStrong.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
