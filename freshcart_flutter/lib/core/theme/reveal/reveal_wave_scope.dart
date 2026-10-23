import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/reveal/reveal_wave_geometry.dart';

/// Shares the current wave with all widgets below it.
///
/// It's an [InheritedNotifier], so widgets that read it rebuild on every
/// animation frame, not only when a new wave starts.
class RevealWaveScope extends InheritedNotifier<AnimationController> {
  /// Creates the scope. [controller] is the same one that drives the
  /// screenshot hole, so everything moves in sync.
  const RevealWaveScope({
    required this.geometry,
    required AnimationController controller,
    required this.curve,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  /// The current wave, or null if no wave is playing. When null, widgets
  /// just use the normal theme.
  final RevealWaveGeometry? geometry;

  /// The animation curve, same as the screenshot hole uses.
  final Curve curve;

  /// The animation. Put `.value` through [curve] to get the progress
  /// (0 to a bit past 1).
  AnimationController get controller => notifier!;

  static RevealWaveScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RevealWaveScope>();

  // Also rebuild dependents when a new wave starts. By default it only
  // checks the controller, which never changes, so widgets would react one
  // frame late.
  @override
  bool updateShouldNotify(covariant RevealWaveScope oldWidget) =>
      super.updateShouldNotify(oldWidget) ||
      oldWidget.geometry != geometry ||
      oldWidget.curve != curve;
}
