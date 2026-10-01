import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';

/// The divider checked items collect under.
///
/// Tappable: folding the trolley away is the whole reason it is a divider and
/// not a plain label. The chevron rotates 180° to say which way the tap goes.
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

  /// "Clear checked", pre-translated. Null hides the action entirely — a
  /// divider with nothing checked to clear has no button to be pressed by
  /// accident.
  final String? clearLabel;

  /// Deletes every checked item. A separate tap target from [onToggle]'s, so
  /// clearing the trolley and folding it away stay two different gestures on
  /// one row rather than one gesture doing two things.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.labelSmall?.color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 9),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              expanded: !collapsed,
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
          if (clearLabel != null && onClear != null)
            InkWell(
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
