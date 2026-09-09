import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  final aliceId = const Uuid().v4();
  final bobId = const Uuid().v4();
  final strangerId = const Uuid().v4();

  withServerpod('Given ItemEndpoint', (sessionBuilder, endpoints) {
    TestSessionBuilder as(String userId) => sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(userId, {}),
    );

    Future<ShoppingList> aSharedList() async {
      final list = await endpoints.list.create(as(aliceId), 'Groceries');
      await endpoints.list.join(as(bobId), list.joinCode);
      return list;
    }

    test('add appends an item attributed to the caller', () async {
      final list = await aSharedList();

      final item = await endpoints.item.add(as(aliceId), list.id!, 'Milk');

      expect(item.name, 'Milk');
      expect(item.quantity, 1);
      expect(item.isChecked, isFalse);
      expect(item.addedBy, UuidValue.withValidation(aliceId));
      expect(item.shopId, isNull);
      expect(item.note, isNull);
    });

    test('add stores a note attributed to the caller', () async {
      final list = await aSharedList();

      final item = await endpoints.item.add(
        as(aliceId),
        list.id!,
        'Milk',
        noteText: 'the oat one',
      );

      expect(item.note?.text, 'the oat one');
      expect(item.note?.authorId, UuidValue.withValidation(aliceId));
    });

    test('any member can add to a shared list', () async {
      final list = await aSharedList();

      final item = await endpoints.item.add(as(bobId), list.id!, 'Bread');

      expect(item.addedBy, UuidValue.withValidation(bobId));
    });

    test('a non-member cannot add to the list', () async {
      final list = await aSharedList();

      await expectLater(
        endpoints.item.add(as(strangerId), list.id!, 'Sneaky'),
        throwsA(isA<NotAMemberException>()),
      );
    });

    test('byList returns the items, and refuses a non-member', () async {
      final list = await aSharedList();
      await endpoints.item.add(as(aliceId), list.id!, 'Milk');

      expect(await endpoints.item.byList(as(bobId), list.id!), hasLength(1));
      await expectLater(
        endpoints.item.byList(as(strangerId), list.id!),
        throwsA(isA<NotAMemberException>()),
      );
    });

    test('save persists an edit and moves updatedAt forward', () async {
      final list = await aSharedList();
      final item = await endpoints.item.add(as(aliceId), list.id!, 'Milk');

      final saved = await endpoints.item.save(
        as(aliceId),
        item.copyWith(name: 'Oat milk', quantity: 2),
      );

      expect(saved.name, 'Oat milk');
      expect(saved.quantity, 2);
      expect(saved.updatedAt.isAfter(item.updatedAt), isTrue);
    });

    test('save rejects a stale write with EditConflictException', () async {
      final list = await aSharedList();
      final item = await endpoints.item.add(as(aliceId), list.id!, 'Milk');

      // Alice and Bob both hold the same version; Bob writes first.
      await endpoints.item.save(as(bobId), item.copyWith(name: 'Bread'));

      // Alice's write still carries the original updatedAt, so it must lose.
      await expectLater(
        endpoints.item.save(as(aliceId), item.copyWith(name: 'Butter')),
        throwsA(isA<EditConflictException>()),
      );
    });

    test('save cannot move an item to another list', () async {
      final list = await aSharedList();
      final other = await endpoints.list.create(as(aliceId), 'Other');
      final item = await endpoints.item.add(as(aliceId), list.id!, 'Milk');

      final saved = await endpoints.item.save(
        as(aliceId),
        item.copyWith(listId: other.id!),
      );

      // listId is server-owned; the client's value is ignored.
      expect(saved.listId, list.id);
    });

    test('save cannot rewrite who added the item', () async {
      final list = await aSharedList();
      final item = await endpoints.item.add(as(aliceId), list.id!, 'Milk');

      final saved = await endpoints.item.save(
        as(bobId),
        item.copyWith(addedBy: UuidValue.withValidation(bobId)),
      );

      expect(saved.addedBy, UuidValue.withValidation(aliceId));
    });

    test('save refuses a non-member', () async {
      final list = await aSharedList();
      final item = await endpoints.item.add(as(aliceId), list.id!, 'Milk');

      await expectLater(
        endpoints.item.save(as(strangerId), item.copyWith(name: 'Sneaky')),
        throwsA(isA<NotAMemberException>()),
      );
    });

    test('remove deletes the item, and refuses a non-member', () async {
      final list = await aSharedList();
      final item = await endpoints.item.add(as(aliceId), list.id!, 'Milk');

      await expectLater(
        endpoints.item.remove(as(strangerId), item.id!),
        throwsA(isA<NotAMemberException>()),
      );

      await endpoints.item.remove(as(bobId), item.id!);
      expect(await endpoints.item.byList(as(aliceId), list.id!), isEmpty);
    });

    test('remove reports a missing item as not found', () async {
      await expectLater(
        endpoints.item.remove(
          as(aliceId),
          UuidValue.withValidation(const Uuid().v4()),
        ),
        throwsA(isA<ItemNotFoundException>()),
      );
    });
  });
}
