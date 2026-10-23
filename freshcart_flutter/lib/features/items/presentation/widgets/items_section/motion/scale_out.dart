import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';

/// Shrinks to 0.6 and fades when hidden, ignoring touches meanwhile.
/// Anchored bottom-right, where the add button sits.
class ScaleOut extends StatelessWidget {
  const ScaleOut({super.key, required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.durationFor(
      context,
      const Duration(milliseconds: 260),
    );
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: duration,
        child: AnimatedScale(
          // Reduced motion: a fade only.
          scale: visible || AppMotion.reduced(context) ? 1 : .6,
          alignment: Alignment.bottomRight,
          duration: duration,
          curve: AppMotion.enter,
          // Out of the semantics tree too, so a screen reader can't reach a
          // button nobody can see.
          child: ExcludeSemantics(excluding: !visible, child: child),
        ),
      ),
    );
  }
}
