import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';

/// The round button at the pill's trailing end: one [Icons.add] glyph that
/// rotates 1/8 turn into an "×" rather than swapping icons, so "the × turns
/// back into a +" is literally what happens.
class QuickAddButton extends StatelessWidget {
  const QuickAddButton({
    required this.showsPlus,
    required this.muted,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  static const double diameter = 44;

  /// + (un-rotated) or × (1/8 turn).
  final bool showsPlus;

  /// Grey while the open field is empty -- nothing to commit yet; shop-
  /// coloured once there's text, or while collapsed (the resting FAB has no
  /// "empty" state of its own).
  final bool muted;
  final String tooltip;

  /// Null while an add is in flight.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // Inside WaveThemed's gated Theme (decisions #90), like QuickAddField.
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: AnimatedContainer(
        key: const ValueKey('quick-add-icon-bg'),
        duration: AppMotion.quick,
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          color: muted
              ? scheme.onSurface.withValues(alpha: 0.08)
              : scheme.primary,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          tooltip: tooltip,
          icon: AnimatedRotation(
            turns: showsPlus ? 0 : 0.125,
            duration: AppMotion.quick,
            // "easeOutBack on the glyph rotation" (§09).
            curve: AppMotion.curveFor(context, AppMotion.pop),
            child: Icon(
              Icons.add,
              color: muted
                  ? scheme.onSurface.withValues(alpha: 0.55)
                  : scheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
