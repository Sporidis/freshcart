import 'package:freshcart_domain/freshcart_domain.dart';

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
