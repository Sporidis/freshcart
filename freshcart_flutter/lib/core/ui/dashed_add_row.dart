import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/dashed_outline_painter.dart';

/// "+ Add another", as a full-width dashed row at the end of a list of
/// cards -- the design's one mark for "add to this collection", the same
/// dash as the shop strip's permanent "+" pill.
///
/// Shared by onboarding's shop step and Manage shops, which list the same
/// kind of card and so end the same way.
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
