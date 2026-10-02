import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';

/// Makes a small button easier to tap (at least 44 x 44), without making it
/// look bigger.
///
/// Wrap the whole control and pass the same tap handler again:
///
///   TapTarget(onTap: add, child: InkWell(onTap: add, child: smallCircle))
///
/// It adds an invisible area around the control. Taps on the control itself
/// still go to its own InkWell (so the ripple still works). Taps on the
/// invisible area are caught here.
///
/// Hidden from screen readers, because the inner control already
/// announces itself.
class TapTarget extends StatelessWidget {
  /// Wraps [child] in a box at least [AppSpacing.minTapTarget] square.
  const TapTarget({
    required this.onTap,
    required this.child,
    this.onTapDown,
    super.key,
  });

  /// The control's own tap handler; null while it is disabled.
  final VoidCallback? onTap;

  /// For controls that need to know where they were tapped. The shop pills
  /// use it to start the colour wave from that spot.
  final GestureTapDownCallback? onTapDown;

  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    excludeFromSemantics: true,
    onTap: onTap,
    onTapDown: onTapDown,
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: AppSpacing.minTapTarget,
        minHeight: AppSpacing.minTapTarget,
      ),
      child: Center(widthFactor: 1, heightFactor: 1, child: child),
    ),
  );
}
