import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/items/application/items/items_controller.dart';
import 'package:freshcart_flutter/features/shops/application/shop_filter/shop_filter_controller.dart';
import 'package:freshcart_flutter/features/shops/application/shops/shops_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shop_tabs_controller.g.dart';

/// The controller for `ShopFilterBar`: which tabs exist, which one is
/// selected, how many items are left in each, and switching tabs.
///
/// Tapping and swiping both go through [select], which updates
/// [ShopFilterController]. So there's only one "selected tab" value.
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
      // Shops turned off in list settings get no tab. They still exist, and
      // items can still be tagged with them.
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

/// The data for the shop tabs. Built by [ShopTabsController].
class ShopTabsState {
  const ShopTabsState({
    required this.allShops,
    required this.tabs,
    required this.selected,
    required this.openItems,
  });

  /// All shops on the list, including hidden ones. A new shop's colour is
  /// compared against all of them.
  final List<Shop> allShops;

  /// The shops that get a tab, in order. "All" isn't in here, it's always
  /// first.
  final List<Shop> tabs;

  /// The selected shop, or null for "All".
  final ShopId? selected;

  final List<ShoppingItem> openItems;

  /// Unchecked items per shop (not the total). Goes down as items are
  /// checked off.
  int remainingIn(ShopId? shop) =>
      openItems.where((item) => item.matchesShopFilter(shop)).length;

  /// The tab [delta] steps from the selected one (for swiping), or null if
  /// there's no tab there.
  ///
  /// Returned as a record `(shopId: ...)` because "All" is a null
  /// [ShopId]. Without the record, null would mean both "All" and "no tab".
  ({ShopId? shopId})? neighbour(int delta) {
    final order = <ShopId?>[null, for (final shop in tabs) shop.id];
    final from = order.indexOf(selected);
    final current = from == -1 ? 0 : from;
    final next = (current + delta).clamp(0, order.length - 1);
    return next == current ? null : (shopId: order[next]);
  }
}
