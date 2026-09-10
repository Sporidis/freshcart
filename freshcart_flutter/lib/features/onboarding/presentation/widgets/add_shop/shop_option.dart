import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:freshcart_flutter/core/preview/preview_harness.dart';
import 'package:freshcart_flutter/core/theme/app_motion.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';

class ShopOption extends StatelessWidget {
  const ShopOption({
    required this.name,
    required this.color,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedScale(
      scale: selected ? 1.015 : 1,
      duration: AppMotion.quick,
      curve: AppMotion.pop,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: AnimatedContainer(
          duration: AppMotion.standard,
          curve: AppMotion.enter,
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screen),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(AppRadii.card),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.22),
                      blurRadius: 12,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            children: [
              Container(
                width: AppSizes.shopDotLarge,
                height: AppSizes.shopDotLarge,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.gap),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: AppMotion.quick,
                switchInCurve: AppMotion.pop,
                switchOutCurve: AppMotion.exit,
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: Icon(
                  key: ValueKey(selected),
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? color : theme.colorScheme.outline,
                  size: AppSizes.checkCircle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ShopOptionEntrance extends StatelessWidget {
  const ShopOptionEntrance({
    required this.index,
    required this.child,
    super.key,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: AppMotion.standard + AppMotion.stagger(index),
      curve: AppMotion.enter,
      tween: Tween(begin: 0, end: 1),
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

@Preview(
  group: 'Onboarding',
  name: 'Shop option · both states',
  size: Size(393, 200),
)
Widget shopOptionPreview() => previewPiece(
  Column(
    mainAxisSize: MainAxisSize.min,
    spacing: 12,
    children: [
      ShopOption(
        name: 'Albert Heijn',
        color: const Color(0xFF2456A6),
        selected: true,
        onTap: () {},
      ),
      ShopOption(
        name: 'Delhaize',
        color: const Color(0xFFC0392B),
        selected: false,
        onTap: () {},
      ),
    ],
  ),
);
