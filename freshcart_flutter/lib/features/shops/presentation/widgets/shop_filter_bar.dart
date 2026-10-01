import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/reveal/shop_theme_reveal.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_theme.dart';
import 'package:freshcart_flutter/features/shops/application/shop/shop_providers.dart';
import 'package:freshcart_flutter/features/shops/application/shop_tabs/shop_tabs_controller.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/add_shop_flow.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_tab_pill.dart';

/// The shop tab strip: "All", one [ShopTabPill] per shop, and a permanent
/// dashed "+" to add another.
///
/// Selecting a tab does two things at once: it narrows the visible items and
/// it re-themes the app to that shop's colour. Both read the same piece of
/// state ([ShopTabsController]), so they cannot disagree -- and a swipe
/// across the strip drives that exact same state a tap would, rather than
/// keeping a second index of its own.
///
/// Unlike the `FilterChip` row this replaces, the strip never hides: "All"
/// and "+" are permanent furniture on every list, shops or not (Component
/// Library §02 -- "The + is permanent furniture on every list").
class ShopFilterBar extends ConsumerWidget {
  /// Creates the bar for [listId].
  const ShopFilterBar({
    required this.listId,
    required this.revealKey,
    super.key,
  });

  /// The list whose shops to show.
  final ListId listId;

  /// The themed body's reveal state -- selecting a tab anchors the colour
  /// reveal at the tap (or, for a swipe, the edge it came from) through
  /// this, before the shop filter itself changes.
  final GlobalKey<ShopThemeRevealState> revealKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final s = ref.watch(shopTabsControllerProvider(listId));

    // Set by each pill's onTapDown, read by its own onTap right after --
    // both are recreated together every build, so this is never stale.
    Offset? tapOrigin;

    // Where to anchor the reveal when there's no tap position to use --
    // defensive only, since a real tap always fires onTapDown before onTap.
    Offset fallbackOrigin() {
      final box = revealKey.currentContext?.findRenderObject();
      if (box is RenderBox && box.hasSize) {
        return box.localToGlobal(box.size.center(Offset.zero));
      }
      return Offset.zero;
    }

    // The reveal has to be anchored *before* the filter provider changes --
    // see [ShopThemeRevealState.beginReveal] -- so every path that changes
    // the filter routes through here rather than calling the provider
    // directly.
    void select(ShopId? shopId, Offset? origin) {
      revealKey.currentState?.beginReveal(origin ?? fallbackOrigin());
      ref.read(shopTabsControllerProvider(listId).notifier).select(shopId);
    }

    // A swipe has no finger position on the *target* tab to anchor to, so
    // it reveals from whichever screen edge the new tab conceptually slides
    // in from instead -- forward (to the right) from the right, backward
    // from the left.
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
        // translucent, not opaque: a swipe still has to reach the
        // ListView underneath so it keeps scrolling normally too, this
        // only *additionally* reacts to a decisive horizontal flick.
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          // A stray drag shouldn't change tabs -- only a real flick, same
          // threshold order of magnitude Dismissible's own swipe uses.
          if (velocity.abs() < 200) return;
          step(velocity < 0 ? 1 : -1);
        },
        child: ListView(
          scrollDirection: Axis.horizontal,
          // Horizontal matches the screen's own edge inset (Theme Reference
          // §05); the inter-pill gap is an explicit SizedBox rather than
          // doubled-up per-pill padding, so it reads as the design's own
          // `gap: 8px` instead of two 4px halves that happen to add up.
          padding: const EdgeInsets.symmetric(
            vertical: 8,
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

/// The permanent dashed "+" that opens [addShop]. A sibling of the tabs,
/// never one of them -- it does not participate in [ShopFilterController] at all.
class _AddShopPill extends StatelessWidget {
  const _AddShopPill({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: CustomPaint(
            painter: _DashedStadiumBorder(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              child: Icon(Icons.add, size: 16),
            ),
          ),
        ),
      ),
    );
  }
}

/// A dashed stadium outline -- Flutter has no built-in dashed [Border], and
/// this is the app's only dashed shape, so a small hand-rolled painter beats
/// pulling in a dependency for one outline.
class _DashedStadiumBorder extends CustomPainter {
  const _DashedStadiumBorder({required this.color});

  final Color color;

  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(size.height / 2),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + _dash),
          paint,
        );
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedStadiumBorder oldDelegate) =>
      oldDelegate.color != color;
}
