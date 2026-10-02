import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';

/// Fades [child] in and slides it up a little, when it first appears.
/// [index] adds a small delay (35 ms per step), so title, text and field
/// come in one after another.
///
/// Each step is rebuilt when you move to it, so this plays again every
/// time, forward or back.
class OnboardingEntrance extends StatelessWidget {
  /// Creates the entrance for the [index]th element of a step.
  const OnboardingEntrance({
    required this.index,
    required this.child,
    super.key,
  });

  /// The order it comes in. 0 is first.
  final int index;

  final Widget child;

  /// How far below its final position it starts.
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
