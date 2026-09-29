import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/items/application/items/items_controller.dart';
import 'package:freshcart_flutter/features/shops/application/shop_filter/shop_filter_controller.dart';
import 'package:freshcart_flutter/features/shops/application/shops/shops_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shop_tabs_controller.g.dart';

/// The view model behind `ShopFilterBar`: which tabs exist, which is
/// selected, how much is left under each, and moving between them.
///
/// Tapping and swiping drive the same [ShopFilterController] through
/// [select], so there is never a second, swipe-only copy of "which tab is
/// active".
@riverpod
class ShopTabsController extends _$ShopTabsController {
  @override
  ShopTabsState build(ListId listId) {
    final shops =
        ref.watch(shopsControllerProvider(listId)).dataOrNull ?? const <Shop>[];
    final items =
        ref.watch(itemsControllerProvider(listId)).dataOrNull ??
        const <ShoppingItem>[];

    return ShopTabsState(
      allShops: shops,
      // Turned off in List settings: still a real shop (still taggable from
      // the item sheet), just not a tab. See Shop.isActive's own doc.
      tabs: [
        for (final shop in shops)
          if (shop.isActive) shop,
      ],
      selected: ref.watch(shopFilterControllerProvider(listId)),
      openItems: [
        for (final item in items)
          if (!item.isChecked) item,
      ],
    );
  }

  /// Filters to [shopId], or back to "All" when null.
  void select(ShopId? shopId) =>
      ref.read(shopFilterControllerProvider(listId).notifier).select(shopId);
}

/// See [ShopTabsController].
class ShopTabsState {
  const ShopTabsState({
    required this.allShops,
    required this.tabs,
    required this.selected,
    required this.openItems,
  });

  /// Every shop on the list, tab or not -- a new shop's colour is checked
  /// against all of them.
  final List<Shop> allShops;

  /// The shops that get a tab, in list order ("All" is implicit, first).
  final List<Shop> tabs;

  /// The selected shop, or null for "All".
  final ShopId? selected;

  final List<ShoppingItem> openItems;

  /// Remaining, not total: the count answers "how much is left to find in
  /// here?", so checking something off makes it tick down.
  int remainingIn(ShopId? shop) =>
      openItems.where((item) => item.matchesShopFilter(shop)).length;

  /// The tab [delta] steps away from the selected one ("All" first, then
  /// each shop), or null when that would run off either end. Wrapped in a
  /// record because "All" is itself a null [ShopId].
  ({ShopId? shopId})? neighbour(int delta) {
    final order = <ShopId?>[null, for (final shop in tabs) shop.id];
    final from = order.indexOf(selected);
    final current = from == -1 ? 0 : from;
    final next = (current + delta).clamp(0, order.length - 1);
    return next == current ? null : (shopId: order[next]);
  }
}
