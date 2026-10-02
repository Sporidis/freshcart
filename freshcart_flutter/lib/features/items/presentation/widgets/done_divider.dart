import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/tap_target.dart';

/// The "Done · 3" line above the checked items.
///
/// Tap it to fold or unfold the checked items. The arrow turns around to
/// show which way.
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

  /// The "Clear checked" text, already translated. Null hides the button.
  final String? clearLabel;

  /// Deletes all checked items. A separate button from folding ([onToggle]).
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.labelSmall?.color;

    return Padding(
      // No vertical padding: the tap areas below set the height, so the
      // whole row can be tapped.
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
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
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Text(
                    clearLabel!,
                    style: AppTextStyles.captionStrong.copyWith(
                      color: theme.colorScheme.primary,
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

@Preview(
  group: 'Items',
  name: 'Done divider · both states',
  size: Size(393, 160),
)
Widget doneDividerPreview() => previewPiece(
  Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      DoneDivider(
        label: 'Done · 3',
        collapsed: false,
        onToggle: () {},
        clearLabel: 'Clear checked',
        onClear: () {},
      ),
      const SizedBox(height: 24),
      DoneDivider(label: 'Done · 3', collapsed: true, onToggle: () {}),
    ],
  ),
);
