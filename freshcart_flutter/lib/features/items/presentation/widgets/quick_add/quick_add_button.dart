import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';

/// The round button at the end of the pill. One "+" icon that rotates 45°
/// to become "×" (not two different icons).
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

  /// Grey while the field is open and empty. Shop colour when there's text,
  /// or when closed.
  final bool muted;
  final String tooltip;

  /// Null (disabled) while an item is being added.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // Theme from inside WaveThemed, so colours follow the wave
    // (decisions.md #90).
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
            // Rotation with a small bounce at the end.
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
