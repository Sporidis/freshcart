import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/dashed_outline_painter.dart';

/// A full-width row with a dashed border, like "+ Add another", shown at
/// the end of a list of cards.
///
/// In the design, a dashed border always means "add something". Used by
/// onboarding and Manage shops.
class DashedAddRow extends StatelessWidget {
  /// Creates the row.
  const DashedAddRow({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: CustomPaint(
          painter: DashedOutlinePainter(
            color: theme.colorScheme.outline,
            radius: AppRadii.card,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.gap,
              vertical: AppSpacing.rowVertical,
            ),
            child: Row(
              children: [
                Icon(Icons.add, size: AppSizes.shopDotLarge, color: muted),
                const SizedBox(width: AppSpacing.gap),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.secondaryStrong.copyWith(color: muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
