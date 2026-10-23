import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';

/// Fades [child] in and lifts it [rise] pixels the first time it builds,
/// after a delay of `start + step * index`, so a group of widgets arrives
/// one after another (the v3 "cascade": sheets 45ms apart, drawer rows and
/// onboarding steps 40ms apart).
///
/// The delay is real: the animation runs for `delay + duration` and the
/// curve only starts moving after the delay, so every item takes the same
/// [duration] to arrive. With reduced motion it's a plain [AppMotion.micro]
/// fade with no rise and no delay.
class CascadeIn extends StatelessWidget {
  const CascadeIn({
    required this.index,
    required this.child,
    this.step = const Duration(milliseconds: 45),
    this.start = Duration.zero,
    this.duration = AppMotion.standard,
    this.rise = 12,
    super.key,
  });

  /// Position in the group. 0 is first. Capped at 6, so a long list doesn't
  /// keep its last rows waiting.
  final int index;
  final Duration step;
  final Duration start;
  final Duration duration;
  final double rise;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final delay = reduced ? Duration.zero : start + step * index.clamp(0, 6);
    final run = reduced ? AppMotion.micro : duration;
    final total = delay + run;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: AppMotion.emphasized,
      ),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, reduced ? 0 : rise * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}
