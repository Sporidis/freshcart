import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/features/items/application/items_controller.dart';
import 'package:freshcart_flutter/features/shops/application/shop_color_preview.dart';
import 'package:freshcart_flutter/features/shops/application/shops_controller.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/add_shop_flow.dart';
import 'package:freshcart_flutter/features/shops/presentation/widgets/shop_tab_pill.dart';

/// The shop tab strip: "All", one [ShopTabPill] per shop, and a permanent
/// dashed "+" to add another.
///
/// Selecting a tab does two things at once: it narrows the visible items and
/// it re-themes the app to that shop's colour. Both read the same piece of
/// state ([shopFilterProvider]), so they cannot disagree -- and a swipe
/// across the strip drives that exact same state a tap would, rather than
/// keeping a second index of its own.
///
/// Unlike the `FilterChip` row this replaces, the strip never hides: "All"
/// and "+" are permanent furniture on every list, shops or not (Component
/// Library §02 -- "The + is permanent furniture on every list").
class ShopFilterBar extends ConsumerWidget {
  /// Creates the bar for [listId].
  const ShopFilterBar({required this.listId, super.key});

  /// The list whose shops to show.
  final ListId listId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final shops = ref.watch(shopsControllerProvider(listId)).dataOrNull ?? const <Shop>[];
    // Turned off in List settings: still a real shop (still taggable from
    // the item sheet), just not a tab here. See Shop.isActive's own doc.
    final activeShops = [
      for (final shop in shops)
        if (shop.isActive) shop,
    ];
    final selected = ref.watch(shopFilterProvider(listId));

    // Remaining, not total: the count answers "how much is left to find in
    // here?", so a checked-off item should make it tick down. Hidden at
    // zero rather than showing "· 0" -- ShopTabPill's own rule.
    final items =
        ref.watch(itemsControllerProvider(listId)).dataOrNull ??
        const <ShoppingItem>[];
    int remainingIn(ShopId? shop) => items
        .where((item) => !item.isChecked && item.matchesShopFilter(shop))
        .length;

    // The one shared "selection model" both tapping and swiping drive:
    // null ("All") first, then every shop in list order. A swipe just
    // steps an index into this and calls the exact select() a tap would --
    // there is no second, swipe-only copy of "which tab is active".
    final order = <ShopId?>[null, for (final shop in activeShops) shop.id];

    void select(ShopId? shopId) =>
        ref.read(shopFilterProvider(listId).notifier).select(shopId);

    void step(int delta) {
      final from = order.indexOf(selected);
      final current = from == -1 ? 0 : from;
      final next = (current + delta).clamp(0, order.length - 1);
      if (next != current) select(order[next]);
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: ShopTabPill(
                label: t.shops.all,
                active: selected == null,
                count: remainingIn(null),
                onTap: () => select(null),
              ),
            ),
            for (final shop in activeShops)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 4,
                ),
                child: ShopTabPill(
                  label: shop.name,
                  active: selected == shop.id,
                  color: Color(ref.watch(effectiveShopColorProvider(shop)).argb),
                  count: remainingIn(shop.id),
                  onTap: () => select(shop.id),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: _AddShopPill(
                tooltip: t.shops.add,
                onTap: () => addShop(context, ref, listId, shops),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The permanent dashed "+" that opens [addShop]. A sibling of the tabs,
/// never one of them -- it does not participate in [ShopFilter] at all.
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
