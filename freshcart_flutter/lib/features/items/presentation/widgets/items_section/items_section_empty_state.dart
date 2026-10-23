import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_empty_state.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_section/floating_cluster.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_section/motion/tab_switch_motion.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// What the items area shows when there are no items: [ItemsEmptyState],
/// naming the shop on a shop tab. Both versions start adding.
class ItemsSectionEmptyState extends StatelessWidget {
  const ItemsSectionEmptyState({
    super.key,
    required this.shop,
    required this.t,
    required this.onAdd,
  });

  /// The selected shop, or null on "All" (or if the shop hasn't loaded).
  /// Null shows the general text.
  final Shop? shop;
  final Translations t;

  /// Opens the add sheet, with the selected shop if there is one.
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final shop = this.shop;
    // A tab switch starts its animation before this builds, so a running
    // one means we got here by switching tabs, not by emptying the tab.
    // Read without depending on it: this only matters when it first shows.
    final switching =
        context
            .getInheritedWidgetOfExactType<TabSwitchScope>()
            ?.notifier
            ?.isAnimating ??
        false;
    final delay = switching
        ? ItemsEmptyState.afterTabSwitch
        : ItemsEmptyState.afterRemoval;
    // Keyed by tab: between two empty tabs a fresh one arrives, instead of
    // the old one being reused with its entrance already played.
    final key = ValueKey(('items-empty', shop?.id));
    // Scrolls, like the list it stands in for: with the ghost card it's
    // taller than a small phone's list area. Top-aligned, as in the design.
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: FloatingCluster.inset),
      // On a shop tab this sits inside the shop's theme (decisions.md #73),
      // so the ghost rings and the pill's plus take the shop's colour.
      child: shop == null
          ? ItemsEmptyState(
              key: key,
              delay: delay,
              title: t.items.emptyTitle,
              body: t.items.emptyBody,
              actionLabel: t.items.emptyShopAction,
              onAction: onAdd,
            )
          : ItemsEmptyState(
              key: key,
              delay: delay,
              title: t.items.emptyShopTitle(shop: shop.name),
              body: t.items.emptyShopBody,
              actionLabel: t.items.addTo(shop: shop.name),
              onAction: onAdd,
            ),
    );
  }
}
