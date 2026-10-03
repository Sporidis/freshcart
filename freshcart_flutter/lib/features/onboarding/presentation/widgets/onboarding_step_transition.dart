import 'package:flutter/widgets.dart';

/// Switches between onboarding (and join) steps, design v3.
///
/// The old step goes at once; the new step's pieces then slide in 36px from
/// the side you're heading to, one after another (see
/// `OnboardingEntrance`). Forward comes from the right, back from the left.
///
/// No crossfade between the two steps: with both on screen, two titles
/// overlap for a moment. v3 swaps and lets the cascade do the moving.
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

  /// +1 moving forward, -1 moving back, for the [OnboardingEntrance]s
  /// below [context]. +1 when there's no transition above (previews).
  static int directionOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_StepDirection>()?.direction ??
      1;

  @override
  State<OnboardingStepTransition> createState() =>
      _OnboardingStepTransitionState();
}

class _OnboardingStepTransitionState extends State<OnboardingStepTransition> {
  int _direction = 1;

  @override
  void didUpdateWidget(OnboardingStepTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _direction = widget.index > oldWidget.index ? 1 : -1;
    }
  }

  @override
  Widget build(BuildContext context) => _StepDirection(
    direction: _direction,
    // A new key per step, so the step is built fresh and its entrances
    // play again, going forward or back.
    child: KeyedSubtree(key: ValueKey(widget.index), child: widget.child),
  );
}

class _StepDirection extends InheritedWidget {
  const _StepDirection({required this.direction, required super.child});

  final int direction;

  @override
  bool updateShouldNotify(_StepDirection oldWidget) =>
      direction != oldWidget.direction;
}
