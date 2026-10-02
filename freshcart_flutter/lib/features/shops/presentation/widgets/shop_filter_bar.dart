import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/reveal/shop_theme_reveal.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/core/ui/dashed_outline_painter.dart';
import 'package:freshcart_flutter/core/ui/tap_target.dart';
import 'package:freshcart_flutter/features/shops/application/shop/shop_providers.dart';
import 'package:freshcart_flutter/features/shops/application/shop_tabs/shop_tabs_controller.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/add_shop_flow.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_tab_pill.dart';

/// The row of shop tabs: "All", one [ShopTabPill] per shop, and a dashed
/// "+" to add a shop.
///
/// Picking a tab filters the items and changes the screen's colour. Both
/// come from [ShopTabsController], so they always match. Swiping left or
/// right on the list changes tabs the same way as tapping.
///
/// Always shown, even with no shops, so "+" is always there.
class ShopFilterBar extends ConsumerWidget {
  /// Creates the bar for [listId].
  const ShopFilterBar({
    required this.listId,
    required this.revealKey,
    super.key,
  });

  /// The list whose shops to show.
  final ListId listId;

  /// Used to start the colour wave from the tap (or from the screen edge
  /// for a swipe), before the filter changes.
  final GlobalKey<ShopThemeRevealState> revealKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final s = ref.watch(shopTabsControllerProvider(listId));

    // Where the finger touched. Saved in onTapDown, used in onTap right
    // after.
    Offset? tapOrigin;

    // Backup start point if there's no tap position. Shouldn't happen,
    // because onTapDown always runs before onTap.
    Offset fallbackOrigin() {
      final box = revealKey.currentContext?.findRenderObject();
      if (box is RenderBox && box.hasSize) {
        return box.localToGlobal(box.size.center(Offset.zero));
      }
      return Offset.zero;
    }

    // The wave must start BEFORE the filter changes (it screenshots the old
    // colour, see [ShopThemeRevealState.beginReveal]). So every tab change
    // goes through here.
    void select(ShopId? shopId, Offset? origin) {
      revealKey.currentState?.beginReveal(origin ?? fallbackOrigin());
      ref.read(shopTabsControllerProvider(listId).notifier).select(shopId);
    }

    // A swipe has no tap position, so the wave starts from a screen edge:
    // next tab from the right edge, previous tab from the left edge.
    Offset? edgeOrigin(int delta) {
      final box = revealKey.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return null;
      final dx = delta > 0 ? box.size.width : 0.0;
      return box.localToGlobal(Offset(dx, box.size.height / 2));
    }

    void step(int delta) {
      final target = s.neighbour(delta);
      if (target != null) select(target.shopId, edgeOrigin(delta));
    }

    return SizedBox(
      height: 56,
      child: GestureDetector(
        // `translucent`, so the list underneath still gets the touches and
        // can scroll. This only adds a reaction to a fast sideways swipe.
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          // Only a fast swipe changes tabs, not a slow drag.
          if (velocity.abs() < 200) return;
          step(velocity < 0 ? 1 : -1);
        },
        child: ListView(
          scrollDirection: Axis.horizontal,
          // Side padding matches the screen edge. Vertical is 6 (not the
          // design's 8): the 56 px bar minus 2×6 leaves exactly the 44 px
          // the pills need to be easy to tap (decisions.md #105).
          padding: const EdgeInsets.symmetric(
            vertical: 6,
            horizontal: AppSpacing.screen,
          ),
          children: [
            ShopTabPill(
              label: t.shops.all,
              active: s.selected == null,
              count: s.remainingIn(null),
              onTapDown: (details) => tapOrigin = details.globalPosition,
              onTap: () => select(null, tapOrigin),
            ),
            for (final shop in s.tabs) ...[
              const SizedBox(width: AppSpacing.gapSmall),
              ShopTabPill(
                label: shop.name,
                active: s.selected == shop.id,
                color: Color(
                  ref.watch(effectiveShopColorProvider(shop)).argb,
                ),
                count: s.remainingIn(shop.id),
                onTapDown: (details) => tapOrigin = details.globalPosition,
                onTap: () => select(shop.id, tapOrigin),
              ),
            ],
            const SizedBox(width: AppSpacing.gapSmall),
            _AddShopPill(
              tooltip: t.shops.add,
              onTap: () => addShop(context, ref, listId, s.allShops),
            ),
          ],
        ),
      ),
    );
  }
}

/// The dashed "+" at the end of the tabs. Opens [addShop]. It's not a tab
/// and can't be selected.
class _AddShopPill extends StatelessWidget {
  const _AddShopPill({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TapTarget(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: CustomPaint(
              painter: DashedOutlinePainter(
                color: theme.colorScheme.outline.withValues(alpha: 0.4),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                child: Icon(Icons.add, size: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
