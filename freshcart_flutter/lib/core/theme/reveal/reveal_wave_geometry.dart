import 'package:flutter/material.dart';

/// Where the current wave started and how big it gets, in screen
/// coordinates.
///
/// Most widgets don't need this, the screenshot trick handles them. But
/// widgets that animate their own colour (like the FAB) would change colour
/// immediately, before the wave reaches them. They use this to wait until the
/// wave actually touches them. See [WaveThemed] and decisions.md #89.
@immutable
class RevealWaveGeometry {
  const RevealWaveGeometry({
    required this.globalOrigin,
    required this.maxRadius,
    required this.oldSeed,
    required this.newSeed,
  });

  /// Where the wave started (a tap, or a screen edge for a swipe).
  final Offset globalOrigin;

  /// How big the circle gets when it covers the whole area.
  final double maxRadius;

  /// The colour before the wave reaches a widget.
  final Color oldSeed;

  /// The colour after the wave reaches a widget.
  final Color newSeed;
}
