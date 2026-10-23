import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/tap_target.dart';

/// The "DONE · 3" line above the checked items (design v3: a mono eyebrow
/// with a quiet "Clear" on the right).
///
/// Tap it to fold or unfold the checked items. The arrow turns around to
/// show which way. The fold is ours, not the design's: kept because a long
/// Done section otherwise pushes the open items' end out of reach.
class DoneDivider extends StatelessWidget {
  /// Creates the divider.
  const DoneDivider({
    required this.label,
    required this.collapsed,
    required this.onToggle,
    this.clearLabel,
    this.onClear,
    super.key,
  });

  /// The already-formatted "Done · 3".
  final String label;

  /// Whether the section below is folded away.
  final bool collapsed;

  /// Called when the divider is tapped.
  final VoidCallback onToggle;

  /// The "Clear" text, already translated. Null hides the button.
  final String? clearLabel;

  /// Deletes all checked items. A separate button from folding ([onToggle]).
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.labelSmall?.color;

    return Padding(
      // Only a top gap: the tap areas below set the height, so the whole
      // row can be tapped.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              expanded: !collapsed,
              child: TapTarget(
                onTap: onToggle,
                child: InkWell(
                  onTap: onToggle,
                  child: Row(
                    children: [
                      AnimatedRotation(
                        turns: collapsed ? -0.25 : 0,
                        duration: AppMotion.durationFor(
                          context,
                          AppMotion.standard,
                        ),
                        curve: AppMotion.enter,
                        child: Icon(Icons.expand_more, size: 16, color: muted),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label.toUpperCase(),
                          style: AppTextStyles.eyebrow.copyWith(color: muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (clearLabel != null && onClear != null)
            TapTarget(
              onTap: onClear,
              child: InkWell(
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 4,
                  ),
                  // Neutral, not the accent: clearing is housekeeping, not
                  // the next thing to do.
                  child: Text(
                    clearLabel!,
                    style: AppTextStyles.secondaryStrong.copyWith(
                      fontSize: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
