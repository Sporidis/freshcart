import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  final aliceId = const Uuid().v4();
  final bobId = const Uuid().v4();
  final strangerId = const Uuid().v4();

  const colruytGreen = 0xFF4CAF50;

  withServerpod('Given ShopEndpoint', (sessionBuilder, endpoints) {
    TestSessionBuilder as(String userId) => sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(userId, {}),
    );

    Future<ShoppingList> aSharedList() async {
      final list = await endpoints.list.create(as(aliceId), 'Groceries');
      await endpoints.list.join(as(bobId), list.joinCode);
      return list;
    }

    test('create adds a shop scoped to the list', () async {
      final list = await aSharedList();

      final shop = await endpoints.shop.create(
        as(aliceId),
        list.id!,
        'Colruyt',
        colruytGreen,
      );

      expect(shop.name, 'Colruyt');
      expect(shop.colorArgb, colruytGreen);
      expect(shop.listId, list.id);
    });

    test('every member sees the same shops', () async {
      // The reason shops are list-scoped rather than user-scoped: a tag one
      // member applies has to mean something to the others.
      final list = await aSharedList();
      await endpoints.shop.create(
        as(aliceId),
        list.id!,
        'Colruyt',
        colruytGreen,
      );

      expect(await endpoints.shop.byList(as(bobId), list.id!), hasLength(1));
    });

    test('a non-member can neither read nor create', () async {
      final list = await aSharedList();

      await expectLater(
        endpoints.shop.byList(as(strangerId), list.id!),
        throwsA(isA<NotAMemberException>()),
      );
      await expectLater(
        endpoints.shop.create(as(strangerId), list.id!, 'Sneaky', colruytGreen),
        throwsA(isA<NotAMemberException>()),
      );
    });

    test('save cannot move a shop to another list', () async {
      final list = await aSharedList();
      final other = await endpoints.list.create(as(aliceId), 'Other');
      final shop = await endpoints.shop.create(
        as(aliceId),
        list.id!,
        'Colruyt',
        colruytGreen,
      );

      final saved = await endpoints.shop.save(
        as(aliceId),
        shop.copyWith(name: 'Delhaize', listId: other.id!),
      );

      expect(saved.name, 'Delhaize');
      expect(saved.listId, list.id, reason: 'listId is server-owned');
    });

    test(
      'deleting a shop untags its items rather than deleting them',
      () async {
        final list = await aSharedList();
        final shop = await endpoints.shop.create(
          as(aliceId),
          list.id!,
          'Colruyt',
          colruytGreen,
        );
        await endpoints.item.add(
          as(aliceId),
          list.id!,
          'Milk',
          shopId: shop.id,
        );

        await endpoints.shop.remove(as(aliceId), shop.id!);

        final items = await endpoints.item.byList(as(aliceId), list.id!);
        expect(
          items,
          hasLength(1),
          reason: 'losing a shop must not lose the shopping',
        );
        expect(items.single.shopId, isNull);
      },
    );

    test('removing a missing shop reports not found', () async {
      await expectLater(
        endpoints.shop.remove(
          as(aliceId),
          UuidValue.withValidation(const Uuid().v4()),
        ),
        throwsA(isA<ShopNotFoundException>()),
      );
    });
  });
}
