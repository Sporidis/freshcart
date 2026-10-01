import 'package:flutter/material.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/features/onboarding/application/onboarding/onboarding_state.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_tab_pill.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// "Your tabs will look like this": the shop strip the list screen will
/// show, built from the shops picked so far.
///
/// Uses the list screen's real [ShopTabPill] rather than a look-alike, so
/// the promise in the label is literally true -- and cannot quietly stop
/// being true the next time the real pill changes.
///
/// Each pill keeps its own identity (keyed by shop name), so toggling a shop
/// animates just that pill in rather than rebuilding the whole row: the
/// design's "every toggle adds a real pill" is the step's payoff, and it
/// only lands if the new pill visibly arrives.
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
        // Decorative: a picture of the strip, not a working one.
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

/// Pops a pill in the first time it mounts -- the same easeOutBack "pop"
/// the rest of the app uses for something newly added.
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
