import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';

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
    super.key,
  });

  /// The already-formatted "Done · 3".
  final String label;

  /// Whether the section below is folded away.
  final bool collapsed;

  /// Called when the divider is tapped.
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.42);

    return Semantics(
      button: true,
      expanded: !collapsed,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 9),
          child: Row(
            children: [
              AnimatedRotation(
                turns: collapsed ? -0.25 : 0,
                duration: AppMotion.durationFor(context, AppMotion.standard),
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
    );
  }
}
