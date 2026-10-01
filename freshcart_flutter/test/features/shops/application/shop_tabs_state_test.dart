import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/shops/application/shop_tabs/shop_tabs_controller.dart';

import '../../../fakes/fake_item_repository.dart';
import '../../../fakes/fake_shop_repository.dart';

void main() {
  final colruyt = buildShop(id: '00000000-0000-4000-8000-0000000000c1');
  final delhaize = buildShop(
    id: '00000000-0000-4000-8000-0000000000c2',
    name: 'Delhaize',
  );

  /// Two shop tabs; [selected] null is "All".
  ShopTabsState state({ShopId? selected}) => ShopTabsState(
    allShops: [colruyt, delhaize],
    tabs: [colruyt, delhaize],
    selected: selected,
    openItems: [
      buildItem(id: '00000000-0000-4000-8000-0000000000a1', shopId: colruyt.id),
      buildItem(id: '00000000-0000-4000-8000-0000000000a2'),
    ],
  );

  group('neighbour', () {
    test('steps from "All" to the first shop', () {
      expect(state().neighbour(1), (shopId: colruyt.id));
    });

    test('steps back to "All", which is a null shop id', () {
      expect(state(selected: colruyt.id).neighbour(-1), (shopId: null));
    });

    test('is null at either end, so nothing moves', () {
      expect(state().neighbour(-1), isNull);
      expect(state(selected: delhaize.id).neighbour(1), isNull);
    });
  });

  test('remainingIn counts open items under each tab', () {
    expect(state().remainingIn(null), 2, reason: '"All" counts everything');
    // The untagged item counts under every shop: a forgotten tag never
    // hides an item (ShoppingItem.matchesShopFilter).
    expect(state().remainingIn(colruyt.id), 2);
    expect(state().remainingIn(delhaize.id), 1);
  });
}
