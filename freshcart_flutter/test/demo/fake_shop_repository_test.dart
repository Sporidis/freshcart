import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';

import 'demo_world.dart';

void main() {
  late DemoWorld world;
  late ListId listId;
  late Shop bakery;
  late Shop market;
  late ShoppingItem bread;

  setUp(() async {
    world = DemoWorld();
    listId = (await world.sharedList()).id;
    Future<Shop> shop(String name) async => (await world.a.shops.create(
      listId: listId,
      name: name,
      color: HexColor.fromArgb(0xFFD99A3D),
    )).valueOrNull!;
    bakery = await shop('Bakery');
    market = await shop('Market');
    bread = (await world.a.items.add(
      listId: listId,
      name: 'Bread',
      shopId: bakery.id,
    )).valueOrNull!;
  });

  test('both users see the list\'s shops', () async {
    final names = [
      for (final s in (await world.b.shops.byList(listId)).valueOrNull!) s.name,
    ];
    expect(names, ['Bakery', 'Market']);
    expect(await world.b.shops.itemCount(bakery.id), const Ok(1));
  });

  test('save keeps the shop on its list', () async {
    final saved = (await world.b.shops.save(
      bakery.toggleActive().copyWith(listId: ListId('elsewhere')),
    )).valueOrNull!;
    expect(saved.isActive, isFalse);
    expect(saved.listId, listId);
  });

  test('remove + untag keeps the items without a shop', () async {
    await world.a.shops.remove(bakery.id);
    expect(world.db.shops.keys, [market.id]);
    expect(world.db.items[bread.id]?.shopId, isNull);
  });

  test('remove + moveToShop moves the items', () async {
    await world.a.shops.remove(
      bakery.id,
      disposition: ShopItemDisposition.moveToShop,
      moveTo: market.id,
    );
    expect(world.db.items[bread.id]?.shopId, market.id);
  });

  test(
    'remove + moveToShop without a target fails and changes nothing',
    () async {
      final result = await world.a.shops.remove(
        bakery.id,
        disposition: ShopItemDisposition.moveToShop,
      );
      expect(result.failureOrNull, isA<NotFoundFailure>());
      expect(world.db.shops, hasLength(2));
    },
  );

  test('remove + deleteItems deletes the items too', () async {
    await world.a.shops.remove(
      bakery.id,
      disposition: ShopItemDisposition.deleteItems,
    );
    expect(world.db.items, isEmpty);
  });
}
