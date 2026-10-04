import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';

import 'demo_world.dart';

void main() {
  late DemoWorld world;

  setUp(() => world = DemoWorld());

  test('create makes the creator the owner', () async {
    final list = (await world.a.lists.create(name: 'Home')).valueOrNull!;
    expect(list.ownerId, DemoWorld.aId);
    expect(list.memberFor(DemoWorld.aId)?.role, MemberRole.owner);
    expect(list.memberFor(DemoWorld.aId)?.displayName, 'Nikolaos');
  });

  test('joining with an unknown code fails like the real app', () async {
    final result = await world.b.lists.joinByCode(
      (JoinCode.parse('ZZZZZ') as Ok<JoinCode>).value,
    );
    expect(result.failureOrNull, isA<ValidationFailure>());
  });

  test('joining adds the user as a member, and twice is harmless', () async {
    final list = await world.sharedList();
    expect(list.memberFor(DemoWorld.bId)?.role, MemberRole.member);

    final again = await world.b.lists.joinByCode(list.joinCode);
    expect(again.valueOrNull?.members, hasLength(2));
  });

  test('a list is invisible to people who are not on it', () async {
    final list = (await world.a.lists.create(name: 'Home')).valueOrNull!;
    expect(
      (await world.b.lists.byId(list.id)).failureOrNull,
      isA<UnauthorizedFailure>(),
    );
    expect((await world.b.lists.myLists()).valueOrNull, isEmpty);
  });

  test('only the owner can rename', () async {
    final list = await world.sharedList();
    expect(
      (await world.b.lists.rename(list.id, 'Mine')).failureOrNull,
      isA<UnauthorizedFailure>(),
    );
    expect(
      (await world.a.lists.rename(list.id, 'Ours')).valueOrNull?.name,
      'Ours',
    );
  });

  test('deleting a list deletes its items and shops', () async {
    final list = await world.sharedList();
    await world.a.items.add(listId: list.id, name: 'Milk');
    await world.a.shops.create(
      listId: list.id,
      name: 'Bakery',
      color: HexColor.fromArgb(0xFFD99A3D),
    );

    expect((await world.a.lists.delete(list.id)).isOk, isTrue);
    expect(world.db.items, isEmpty);
    expect(world.db.shops, isEmpty);
  });

  test('transferOwnership swaps the roles', () async {
    final list = await world.sharedList();
    final moved = (await world.a.lists.transferOwnership(
      list.id,
      DemoWorld.bId,
    )).valueOrNull!;
    expect(moved.ownerId, DemoWorld.bId);
    expect(moved.memberFor(DemoWorld.aId)?.role, MemberRole.member);
    expect(moved.memberFor(DemoWorld.bId)?.role, MemberRole.owner);
  });

  test('the owner cannot be removed', () async {
    final list = await world.sharedList();
    expect(
      (await world.a.lists.removeMember(list.id, DemoWorld.aId)).failureOrNull,
      isA<UnauthorizedFailure>(),
    );
    expect(
      (await world.a.lists.removeMember(list.id, DemoWorld.bId)).isOk,
      isTrue,
    );
  });

  test('summaries count items and checked items', () async {
    final list = await world.sharedList();
    await world.a.items.add(listId: list.id, name: 'Milk');
    final bread = (await world.a.items.add(
      listId: list.id,
      name: 'Bread',
    )).valueOrNull!;
    await world.b.items.save(
      bread.toggleChecked(by: DemoWorld.bId, at: bread.updatedAt),
    );

    final summary = (await world.a.lists.summaries([list.id])).valueOrNull!;
    expect(summary.single.total, 2);
    expect(summary.single.checkedCount, 1);
  });

  test("watch shows the other user's change", () async {
    final list = await world.sharedList();
    final names = <String?>[];
    final sub = world.b.lists
        .watch(list.id)
        .listen(
          (r) => names.add(r.valueOrNull?.name),
        );
    await pumpEventQueue();

    await world.a.lists.rename(list.id, 'Weekend');
    await pumpEventQueue();
    await sub.cancel();

    expect(names, ['Home', 'Weekend']);
  });
}
