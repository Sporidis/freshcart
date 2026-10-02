import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_state.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_tab_pill.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// "Your tabs will look like this": a preview of the shop tabs, using the
/// shops picked so far.
///
/// Uses the real [ShopTabPill], so the preview always matches the real
/// tabs.
///
/// Each pill has a key (the shop name), so when a shop is picked only that
/// pill animates in. The rest of the row stays still.
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
        const SizedBox(height: AppSpacing.gapSmall),
        // Just a picture: the pills can't be tapped.
        IgnorePointer(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: AnimatedSize(
              duration: AppMotion.durationFor(context, AppMotion.standard),
              curve: AppMotion.enter,
              alignment: Alignment.centerLeft,
              child: Row(
                spacing: AppSpacing.gapSmall,
                children: [
                  ShopTabPill(label: t.onboarding.allTab, active: true),
                  for (final shop in shops)
                    _PillArrival(
                      key: ValueKey(shop.name),
                      child: ShopTabPill(
                        label: shop.name,
                        active: false,
                        color: shop.color.toColor(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Makes a pill "pop" in (grow with a small bounce) when it first appears.
class _PillArrival extends StatelessWidget {
  const _PillArrival({required this.child, super.key});

  final Widget child;

  static const double _startScale = 0.6;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.durationFor(context, AppMotion.bouncy),
      curve: AppMotion.curveFor(context, AppMotion.pop),
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: _startScale + (1 - _startScale) * value,
          child: child,
        ),
      ),
    );
  }
}
