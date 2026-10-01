import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';

/// Grows a small control's hit area to the 44pt minimum without changing
/// how it looks.
///
/// Wraps the *whole* control, InkWell and all, and repeats its handler:
///
///   TapTarget(onTap: add, child: InkWell(onTap: add, child: smallCircle))
///
/// Flutter hit-tests by layout box -- a widget only receives taps inside its
/// own size -- so the box has to grow for the target to grow. The margin it
/// adds is transparent, and a tap on the control itself still goes to the
/// inner InkWell (the deepest tap recognizer wins the gesture arena), so the
/// ripple is untouched; this detector only ever catches the margin.
///
/// Excluded from semantics: the inner control already announces itself, and
/// a second nested "button" node would be read twice.
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

  /// For controls that care where they were tapped (the shop pills anchor
  /// the theme reveal to it).
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
