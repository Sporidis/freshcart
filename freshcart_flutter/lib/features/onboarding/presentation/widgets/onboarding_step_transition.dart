import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';

/// The animation between onboarding steps:
///
/// - the old step slides 24 px away and fades out (200 ms);
/// - after a short pause (60 ms), the new step slides in from 32 px on the
///   other side and fades in (320 ms);
/// - going back does the same in the other direction.
///
/// Only the content moves, not the whole page. The back arrow, step
/// indicator and Continue stay put.
///
/// [index] is the step number. A higher number than before means forward.
class OnboardingStepTransition extends StatefulWidget {
  /// Creates the transition, showing [child] as step [index].
  const OnboardingStepTransition({
    required this.index,
    required this.child,
    super.key,
  });

  final int index;
  final Widget child;

  @override
  State<OnboardingStepTransition> createState() =>
      _OnboardingStepTransitionState();
}

class _OnboardingStepTransitionState extends State<OnboardingStepTransition> {
  static const double _outTravel = 24;
  static const double _inTravel = 32;

  /// +1 moving forward, -1 moving back.
  int _direction = 1;

  @override
  void didUpdateWidget(OnboardingStepTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _direction = widget.index > oldWidget.index ? 1 : -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final inTotal = AppMotion.stepInDelay + AppMotion.stepIn;
    final delayFraction =
        AppMotion.stepInDelay.inMicroseconds / inTotal.inMicroseconds;
    final currentKey = ValueKey(widget.index);
    final direction = _direction;

    return AnimatedSwitcher(
      duration: reduced ? AppMotion.micro : inTotal,
      reverseDuration: reduced ? AppMotion.micro : AppMotion.stepOut,
      // Full size and aligned to the top. Otherwise a short step would float
      // to the middle during the animation.
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) {
        final incoming = child.key == currentKey;
        // The old step's animation runs backwards (1 -> 0), so it uses the
        // reverse curve. The new step waits for the pause first.
        final curved = incoming
            ? CurvedAnimation(
                parent: animation,
                curve: Interval(delayFraction, 1, curve: AppMotion.enter),
              )
            : CurvedAnimation(
                parent: animation,
                curve: AppMotion.enter,
                reverseCurve: AppMotion.exit,
              );
        return AnimatedBuilder(
          animation: curved,
          child: child,
          builder: (context, child) {
            final remaining = 1 - curved.value;
            final dx = reduced
                ? 0.0
                : incoming
                ? _inTravel * direction * remaining
                : -_outTravel * direction * remaining;
            return Opacity(
              opacity: curved.value,
              child: Transform.translate(offset: Offset(dx, 0), child: child),
            );
          },
        );
      },
      child: KeyedSubtree(key: currentKey, child: widget.child),
    );
  }
}
