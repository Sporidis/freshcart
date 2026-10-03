import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/features/onboarding/presentation/widgets/onboarding_step_transition.dart';

/// Brings one piece of a step in (design v3): it slides 36px in from the
/// side you're heading to and fades in, over 340ms. [index] waits 40ms per
/// step, so title, text and field arrive one after another.
///
/// The direction comes from [OnboardingStepTransition]: from the right when
/// going forward, from the left when going back. Each step is rebuilt when
/// you move to it, so this plays every time.
///
/// Reduced motion: a 120ms fade, no travel.
class OnboardingEntrance extends StatelessWidget {
  /// Creates the entrance for the [index]th piece of a step.
  const OnboardingEntrance({
    required this.index,
    required this.child,
    super.key,
  });

  /// The order it comes in. 0 is first.
  final int index;

  final Widget child;

  static const double _travel = 36;
  static const Duration _stagger = Duration(milliseconds: 40);

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final direction = OnboardingStepTransition.directionOf(context);
    final delay = reduced ? Duration.zero : _stagger * index;
    final move = reduced ? AppMotion.micro : AppMotion.onboardingStep;
    final total = delay + move;
    final start = delay.inMicroseconds / total.inMicroseconds;

    return TweenAnimationBuilder<double>(
      duration: total,
      // The wait is part of the curve: flat until [start], then the move.
      curve: Interval(start, 1, curve: AppMotion.enter),
      tween: Tween(begin: 0, end: 1),
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(
            reduced ? 0 : _travel * direction * (1 - value),
            0,
          ),
          child: child,
        ),
      ),
    );
  }
}
