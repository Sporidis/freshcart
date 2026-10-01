import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';

/// Swaps one onboarding step for the next with the Motion spec's authored
/// transition (§07), rather than a full-width page slide:
///
/// - outgoing: slides 24 px the way it is leaving and fades out, 200 ms
///   easeInCubic;
/// - incoming: starts 32 px off on the far side and fades in, 320 ms
///   easeOutCubic after a 60 ms beat;
/// - going back mirrors both directions.
///
/// Shorter travel than a page slide on purpose: the steps share their
/// chrome (back arrow, step rail, Continue), so only the content changes,
/// and a whole-page slide made the unchanged chrome look like it moved too.
///
/// [index] is the step's position in its flow; a higher index than last
/// time means forward. Each [child] is remounted on arrival, which is what
/// replays its [OnboardingEntrance] stagger.
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
      // Full-size, top-aligned pages: the default centred, loosely-sized
      // Stack would let a short step float to the middle mid-transition.
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) {
        final incoming = child.key == currentKey;
        // An outgoing child's animation runs 1 -> 0, so its curve is the
        // reverse one; an incoming child's waits out the delay first.
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
