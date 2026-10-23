import 'package:flutter/material.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/strike_through.dart';

/// Makes [child] more see-through as [progress] goes from 0 to 1, down to
/// [maxFade]. Used for checked-off rows, together with [StrikeThrough].
///
/// A separate widget because the line only goes around the item's name,
/// but the fade goes around the whole row.
class CheckedFade extends StatelessWidget {
  const CheckedFade({
    required this.progress,
    required this.child,
    this.maxFade = 0.55,
    super.key,
  });

  final Animation<double> progress;
  final Widget child;
  final double maxFade;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) =>
          Opacity(opacity: 1 - (progress.value * maxFade), child: child),
      child: child,
    );
  }
}
