import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/features/onboarding/application/screen/onboarding_state.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

class ShopTabsPreview extends StatelessWidget {
  const ShopTabsPreview({required this.shops, required this.t, super.key});

  final List<OnboardingShopDraft> shops;

  /// Translations for the active locale.
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.onboarding.tabsPreviewLabel.toUpperCase(),
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
                  label: t.onboarding.allTab,
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
            // Not a real Chip, so ChipThemeData does not apply here — the
            // selected pill's own fill colour decides its text colour
            // directly, the same contrast rule AppTheme uses for a shop's
            // `onPrimary` (docs/decisions.md, the theming-fidelity entry).
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected
                  ? (ThemeData.estimateBrightnessForColor(color) ==
                            Brightness.dark
                        ? Colors.white
                        : AppColors.ink)
                  : theme.colorScheme.onSurface,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
