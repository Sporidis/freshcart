import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';

import 'demo_world.dart';

void main() {
  late DemoWorld world;
  late ListId listId;

  setUp(() async {
    world = DemoWorld();
    listId = (await world.sharedList()).id;
  });

  Future<ShoppingItem> add(String name, {DemoPhoneFakes? by}) async =>
      (await (by ?? world.a).items.add(
        listId: listId,
        name: name,
      )).valueOrNull!;

  test("an item A adds shows up in B's watchByList", () async {
    final snapshots = <List<String>>[];
    final sub = world.b.items
        .watchByList(listId)
        .listen(
          (r) => snapshots.add([for (final i in r.valueOrNull!) i.name]),
        );
    await pumpEventQueue();

    await add('Milk');
    await pumpEventQueue();
    await sub.cancel();

    expect(snapshots, [
      <String>[],
      ['Milk'],
    ]);
  });

  test('add records who added it and appends to the end', () async {
    final milk = await add('Milk');
    final bread = await add('Bread', by: world.b);
    expect(milk.addedBy, DemoWorld.aId);
    expect(bread.addedBy, DemoWorld.bId);
    expect(bread.sortOrder, greaterThan(milk.sortOrder));
  });

  test('adding the same open product bumps its quantity', () async {
    final first = await add('Milk');
    final second = await add(' Milk ', by: world.b);
    expect(second.id, first.id);
    expect(second.quantity, 2);
    expect((await world.a.items.byList(listId)).valueOrNull, hasLength(1));
  });

  test('saving a stale copy is a conflict', () async {
    final stale = await add('Milk');
    await world.b.items.save(stale.copyWith(quantity: 3));

    final result = await world.a.items.save(stale.copyWith(quantity: 5));
    expect(result.failureOrNull, isA<ConflictFailure>());
  });

  test('the fake server decides who checked an item', () async {
    final milk = await add('Milk');
    // A claims to be the checker, but B is the one saving.
    final saved = (await world.b.items.save(
      milk.toggleChecked(by: DemoWorld.aId, at: milk.updatedAt),
    )).valueOrNull!;
    expect(saved.isChecked, isTrue);
    expect(saved.checkedBy, DemoWorld.bId);
  });

  test('clearChecked removes only checked items', () async {
    final milk = await add('Milk');
    await add('Bread');
    await world.a.items.save(
      milk.toggleChecked(by: DemoWorld.aId, at: milk.updatedAt),
    );

    expect(await world.a.items.clearChecked(listId), const Ok(1));
    final left = (await world.a.items.byList(listId)).valueOrNull!;
    expect([for (final i in left) i.name], ['Bread']);
  });

  test('moveMany and removeMany return how many they changed', () async {
    final shop = (await world.a.shops.create(
      listId: listId,
      name: 'Bakery',
      color: HexColor.fromArgb(0xFF7E9CDB),
    )).valueOrNull!;
    final milk = await add('Milk');
    final bread = await add('Bread');

    expect(
      await world.a.items.moveMany(listId, [milk.id, bread.id], shop.id),
      const Ok(2),
    );
    expect(world.db.items[milk.id]?.shopId, shop.id);

    expect(await world.a.items.removeMany(listId, [milk.id]), const Ok(1));
    expect(world.db.items.keys, [bread.id]);
  });

  test('someone not on the list cannot add to it', () async {
    final other = DemoPhoneFakes(world.db, UserId('stranger'));
    final result = await other.items.add(listId: listId, name: 'Milk');
    expect(result.failureOrNull, isA<UnauthorizedFailure>());
  });
}
