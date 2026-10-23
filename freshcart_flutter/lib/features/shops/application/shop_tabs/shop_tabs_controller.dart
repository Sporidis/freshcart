import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/items/application/items/items_controller.dart';
import 'package:freshcart_flutter/features/shops/application/shop_filter/shop_filter_controller.dart';
import 'package:freshcart_flutter/features/shops/application/shop_tabs/shop_tabs_state.dart';
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
