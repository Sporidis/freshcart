import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/app_theme.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding_state.dart';

class ShopTabsPreview extends StatelessWidget {
  const ShopTabsPreview({required this.shops, super.key});

  final List<OnboardingShopDraft> shops;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR TABS WILL LOOK LIKE THIS',
          style: theme.textTheme.labelSmall,
        ),
        const SizedBox(height: AppSpacing.gap),
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: SingleChildScrollView(
            key: ValueKey(shops.map((shop) => shop.name).join('|')),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                TabPill(
                  label: 'All',
                  selected: true,
                  color: theme.colorScheme.onSurface,
                ),
                ...shops.map(
                  (shop) => Padding(
                    key: ValueKey(shop.name),
                    padding: const EdgeInsets.only(left: AppSpacing.gap),
                    child: TabPill(
                      label: shop.name,
                      color: _flutterColor(shop.color),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Color _flutterColor(HexColor color) => Color.fromARGB(
  color.alpha,
  color.red,
  color.green,
  color.blue,
);

class TabPill extends StatelessWidget {
  const TabPill({
    required this.label,
    required this.color,
    this.selected = false,
    super.key,
  });

  final String label;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!selected) ...[
            Container(
              width: AppSizes.tabDot,
              height: AppSizes.tabDot,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.gapSmall),
          ],
          Text(
            label,
            style: selected
                ? theme.chipTheme.secondaryLabelStyle
                : theme.chipTheme.labelStyle,
          ),
        ],
      ),
    );
  }
}
