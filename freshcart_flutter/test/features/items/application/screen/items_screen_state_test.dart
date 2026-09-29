import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/items/application/screen/items_screen_state.dart';

import '../../../../fakes/fake_item_repository.dart';
import '../../../../fakes/fake_list_repository.dart';

void main() {
  // A plain value: no container, no providers -- the whole point of keeping
  // the derivations on the state rather than in the widget.
  ItemsScreenState stateWith({
    required List<ShoppingItem> items,
    String query = '',
    ShopId? shopFilter,
  }) => ItemsScreenState(
    list: buildList(),
    mode: ItemsMode.search,
    allItems: items,
    shops: const [],
    shopFilter: shopFilter,
    me: null,
    selection: const {},
    searchQuery: query,
    doneCollapsed: false,
    showCelebration: false,
  );

  var nextId = 0;
  ShoppingItem item(String name, {bool isChecked = false, ShopId? shopId}) =>
      buildItem(
        id: '00000000-0000-4000-8000-${(nextId++).toString().padLeft(12, '0')}',
        name: name,
        isChecked: isChecked,
        shopId: shopId,
      );

  List<String> names(List<ShoppingItem> items) => [
    for (final i in items) i.name,
  ];

  group('trimmedQuery', () {
    test('drops the whitespace a keyboard leaves behind', () {
      expect(stateWith(items: const [], query: '  milk ').trimmedQuery, 'milk');
    });
  });

  group('searchMatches', () {
    test('matches regardless of case, in either direction', () {
      final state = stateWith(
        items: [item('Milk'), item('OAT MILK'), item('Bread')],
        query: 'mILk',
      );

      expect(names(state.searchMatches), ['Milk', 'OAT MILK']);
    });

    test('a trailing space in the query does not hide a match', () {
      final state = stateWith(items: [item('Milk')], query: 'milk ');

      expect(names(state.searchMatches), ['Milk']);
    });

    test('matches anywhere in the name, not just the start', () {
      final state = stateWith(
        items: [item('Oat milk'), item('Bread')],
        query: 'milk',
      );

      expect(names(state.searchMatches), ['Oat milk']);
    });

    test('ignores the shop filter -- search spans every shop (§16)', () {
      final lidl = ShopId('00000000-0000-4000-8000-00000000b001');
      final aldi = ShopId('00000000-0000-4000-8000-00000000b002');
      final state = stateWith(
        items: [
          item('Milk', shopId: lidl),
          item('Milk chocolate', shopId: aldi),
        ],
        query: 'milk',
        shopFilter: lidl,
      );

      expect(names(state.searchMatches), ['Milk', 'Milk chocolate']);
    });

    test('includes checked items, not just open ones', () {
      final state = stateWith(
        items: [item('Milk', isChecked: true), item('Oat milk')],
        query: 'milk',
      );

      expect(names(state.searchMatches), ['Milk', 'Oat milk']);
    });

    test('keeps the list order', () {
      final state = stateWith(
        items: [item('Soy milk'), item('Milk'), item('Oat milk')],
        query: 'milk',
      );

      expect(names(state.searchMatches), ['Soy milk', 'Milk', 'Oat milk']);
    });

    test('no match is an empty list, not an error', () {
      final state = stateWith(items: [item('Bread')], query: 'milk');

      expect(state.searchMatches, isEmpty);
    });

    // TODO: pin down what an empty or whitespace-only query returns.
  });
}
