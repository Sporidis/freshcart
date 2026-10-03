import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/items/application/items_section/item_arrivals.dart';

import '../../../fakes/fake_item_repository.dart';

void main() {
  final milk = buildItem(id: 'milk', name: 'Milk');
  final bread = buildItem(id: 'bread', name: 'Bread');

  test('the first load brings nothing "new"', () {
    expect(itemArrivals(null, [milk, bread]), isEmpty);
  });

  test('an id that wasn\'t there before has arrived', () {
    expect(itemArrivals([milk], [milk, bread]), {bread.id});
  });

  test('changes to rows already there are not arrivals', () {
    final ticked = milk.copyWith(isChecked: true);
    expect(itemArrivals([milk, bread], [ticked, bread]), isEmpty);
  });

  test('an offline item syncing (temporary row swapped for the real one) '
      'is not an arrival', () {
    final offline = buildItem(id: 'temp-1', name: 'Eggs').copyWith(
      pending: true,
    );
    final synced = buildItem(id: 'real-1', name: 'Eggs');
    expect(itemArrivals([milk, offline], [milk, synced]), isEmpty);
  });

  test('a genuinely new item still arrives while another one syncs', () {
    final offline = buildItem(id: 'temp-1', name: 'Eggs').copyWith(
      pending: true,
    );
    final synced = buildItem(id: 'real-1', name: 'Eggs');
    final cheese = buildItem(id: 'cheese', name: 'Cheese');
    expect(
      itemArrivals([milk, offline], [milk, synced, cheese]),
      {ItemId('cheese')},
    );
  });
}
