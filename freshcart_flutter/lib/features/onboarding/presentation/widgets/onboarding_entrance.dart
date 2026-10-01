import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';

/// Fades and lifts [child] in once, when it first mounts, [index] stagger
/// steps after its siblings (Motion spec §07: "title, body, field stagger
/// 35 ms apart via AppMotion.stagger").
///
/// Because every onboarding step is remounted on each transition, this
/// replays on every step arrival -- forward or back -- without any explicit
/// trigger.
class OnboardingEntrance extends StatelessWidget {
  /// Creates the entrance for the [index]th element of a step.
  const OnboardingEntrance({
    required this.index,
    required this.child,
    super.key,
  });

  /// Position among the elements entering together; 0 enters first.
  final int index;

  final Widget child;

  /// How far below its resting place the element starts.
  static const double _rise = 12;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: AppMotion.durationFor(
        context,
        AppMotion.standard + AppMotion.stagger(index),
      ),
      curve: AppMotion.enter,
      tween: Tween(begin: 0, end: 1),
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, _rise * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}
