import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_fill.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_radii.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_text_styles.dart';

/// The sheet's amount: a compact "− 2 +" on the fill colour, the + raised
/// on the surface. Smaller and quieter than the row stepper, because here
/// the amount is usually already right.
class CompactQuantityStepper extends StatelessWidget {
  const CompactQuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    required this.decreaseLabel,
    required this.increaseLabel,
    super.key,
  });

  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;
  final String decreaseLabel;
  final String increaseLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget button({
      required IconData icon,
      required String label,
      required VoidCallback? onTap,
      bool raised = false,
    }) => Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          opacity: onTap == null ? .3 : 1,
          duration: AppMotion.durationFor(context, AppMotion.quick),
          child: Container(
            width: 34,
            height: 34,
            decoration: raised
                ? BoxDecoration(
                    color: scheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .12),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  )
                : null,
            child: Icon(icon, size: 16, color: scheme.onSurface),
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.fill,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(
            icon: Icons.remove,
            label: decreaseLabel,
            onTap: onDecrement,
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyStrong.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          button(
            icon: Icons.add,
            label: increaseLabel,
            onTap: onIncrement,
            raised: true,
          ),
        ],
      ),
    );
  }
}
