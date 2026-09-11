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

    test('byList orders by sortOrder, not creation order', () async {
      final list = await aSharedList();
      final milk = await endpoints.item.add(as(aliceId), list.id!, 'Milk');
      final bread = await endpoints.item.add(as(aliceId), list.id!, 'Bread');
      await endpoints.item.add(as(aliceId), list.id!, 'Eggs');

      // Drag Bread above Milk -- a plain save carrying a lower sortOrder,
      // the same write path every other edit takes.
      await endpoints.item.save(
        as(aliceId),
        bread.copyWith(sortOrder: milk.sortOrder - 1),
      );

      final items = await endpoints.item.byList(as(aliceId), list.id!);
      expect(items.map((i) => i.name), ['Bread', 'Milk', 'Eggs']);
    });

    test('add appends past the current end, spaced for future reorders', () async {
      final list = await aSharedList();
      final milk = await endpoints.item.add(as(aliceId), list.id!, 'Milk');
      final bread = await endpoints.item.add(as(aliceId), list.id!, 'Bread');

      expect(bread.sortOrder, greaterThan(milk.sortOrder));
      expect(
        bread.sortOrder - milk.sortOrder,
        greaterThan(1),
        reason: 'a real gap, not consecutive integers -- see sortOrderGap',
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

    test(
      'clearChecked deletes every checked item and leaves the rest',
      () async {
        final list = await aSharedList();
        final milk = await endpoints.item.add(as(aliceId), list.id!, 'Milk');
        final bread = await endpoints.item.add(as(aliceId), list.id!, 'Bread');
        final eggs = await endpoints.item.add(as(aliceId), list.id!, 'Eggs');
        await endpoints.item.save(
          as(aliceId),
          milk.copyWith(isChecked: true),
        );
        await endpoints.item.save(
          as(aliceId),
          bread.copyWith(isChecked: true),
        );

        final removed = await endpoints.item.clearChecked(
          as(aliceId),
          list.id!,
        );

        expect(removed, 2);
        final remaining = await endpoints.item.byList(as(aliceId), list.id!);
        expect(remaining.map((i) => i.id), [eggs.id]);
      },
    );

    test('clearChecked refuses a non-member', () async {
      final list = await aSharedList();
      await expectLater(
        endpoints.item.clearChecked(as(strangerId), list.id!),
        throwsA(isA<NotAMemberException>()),
      );
    });

    test('clearChecked is a no-op when nothing is checked', () async {
      final list = await aSharedList();
      await endpoints.item.add(as(aliceId), list.id!, 'Milk');

      expect(await endpoints.item.clearChecked(as(aliceId), list.id!), 0);
      expect(await endpoints.item.byList(as(aliceId), list.id!), hasLength(1));
    });

    test(
      'removeMany deletes exactly the selected items and leaves the rest',
      () async {
        final list = await aSharedList();
        final milk = await endpoints.item.add(as(aliceId), list.id!, 'Milk');
        final bread = await endpoints.item.add(as(aliceId), list.id!, 'Bread');
        final eggs = await endpoints.item.add(as(aliceId), list.id!, 'Eggs');

        final removed = await endpoints.item.removeMany(as(aliceId), list.id!, [
          milk.id!,
          bread.id!,
        ]);

        expect(removed, 2);
        final remaining = await endpoints.item.byList(as(aliceId), list.id!);
        expect(remaining.map((i) => i.id), [eggs.id]);
      },
    );

    test('removeMany refuses a non-member', () async {
      final list = await aSharedList();
      final milk = await endpoints.item.add(as(aliceId), list.id!, 'Milk');

      await expectLater(
        endpoints.item.removeMany(as(strangerId), list.id!, [milk.id!]),
        throwsA(isA<NotAMemberException>()),
      );
    });

    test('removeMany ignores an id from another list', () async {
      final list = await aSharedList();
      final other = await endpoints.list.create(as(aliceId), 'Other');
      final milk = await endpoints.item.add(as(aliceId), list.id!, 'Milk');
      final elsewhere = await endpoints.item.add(
        as(aliceId),
        other.id!,
        'Sneaky',
      );

      final removed = await endpoints.item.removeMany(as(aliceId), list.id!, [
        milk.id!,
        elsewhere.id!,
      ]);

      expect(removed, 1, reason: 'only the item that actually belongs here');
      expect(
        await endpoints.item.byList(as(aliceId), other.id!),
        hasLength(1),
        reason: 'the other list is untouched',
      );
    });

    test('removeMany is a no-op on an empty selection', () async {
      final list = await aSharedList();
      await endpoints.item.add(as(aliceId), list.id!, 'Milk');

      expect(await endpoints.item.removeMany(as(aliceId), list.id!, []), 0);
      expect(await endpoints.item.byList(as(aliceId), list.id!), hasLength(1));
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

    test(
      'checking records the caller, not whoever the client claims',
      () async {
        final list = await aSharedList();
        final item = await endpoints.item.add(as(aliceId), list.id!, 'Milk');

        // Bob ticks it but claims Alice did. The server must not believe him:
        // on a shared list, "checked off by" is the one label that has to be
        // trustworthy.
        final saved = await endpoints.item.save(
          as(bobId),
          item.copyWith(
            isChecked: true,
            checkedBy: UuidValue.withValidation(aliceId),
          ),
        );

        expect(saved.isChecked, isTrue);
        expect(saved.checkedBy, UuidValue.withValidation(bobId));
        expect(saved.checkedAt, isNotNull);
      },
    );

    test('unchecking clears the attribution', () async {
      final list = await aSharedList();
      final item = await endpoints.item.add(as(aliceId), list.id!, 'Milk');
      final checked = await endpoints.item.save(
        as(aliceId),
        item.copyWith(isChecked: true),
      );

      final unchecked = await endpoints.item.save(
        as(bobId),
        checked.copyWith(isChecked: false),
      );

      expect(unchecked.isChecked, isFalse);
      expect(unchecked.checkedBy, isNull);
      expect(unchecked.checkedAt, isNull);
    });

    test('editing a checked item leaves its attribution alone', () async {
      final list = await aSharedList();
      final item = await endpoints.item.add(as(aliceId), list.id!, 'Milk');
      final checked = await endpoints.item.save(
        as(aliceId),
        item.copyWith(isChecked: true),
      );

      // Bob renames it without touching the checkbox.
      final renamed = await endpoints.item.save(
        as(bobId),
        checked.copyWith(name: 'Oat milk'),
      );

      expect(renamed.name, 'Oat milk');
      expect(renamed.checkedBy, UuidValue.withValidation(aliceId));
      expect(renamed.checkedAt, checked.checkedAt);
    });

    test('me() reports the caller derived from the session', () async {
      final me = await endpoints.profile.me(as(aliceId));
      expect(me.userId, UuidValue.withValidation(aliceId));
      expect(me.displayName, isNotEmpty);
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

    group('suggestNames', () {
      test('an added name becomes a suggestion, matched case-insensitively', () async {
        final list = await aSharedList();
        await endpoints.item.add(as(aliceId), list.id!, 'Olive oil');

        final suggestions = await endpoints.item.suggestNames(
          as(aliceId),
          list.id!,
          'oliv',
        );

        expect(suggestions, ['Olive oil']);
      });

      test('nothing under two characters -- too broad to be a suggestion', () async {
        final list = await aSharedList();
        await endpoints.item.add(as(aliceId), list.id!, 'Olive oil');

        expect(
          await endpoints.item.suggestNames(as(aliceId), list.id!, 'o'),
          isEmpty,
        );
      });

      test('adding the same name again does not duplicate the suggestion', () async {
        final list = await aSharedList();
        await endpoints.item.add(as(aliceId), list.id!, 'Milk');
        await endpoints.item.add(as(bobId), list.id!, 'Milk');

        final suggestions = await endpoints.item.suggestNames(
          as(aliceId),
          list.id!,
          'milk',
        );

        expect(suggestions, ['Milk']);
      });

      test('most recently used first', () async {
        final list = await aSharedList();
        await endpoints.item.add(as(aliceId), list.id!, 'Apple');
        await endpoints.item.add(as(aliceId), list.id!, 'Apricot');
        // Re-adding "Apple" bumps it back to the front.
        await endpoints.item.add(as(aliceId), list.id!, 'Apple');

        final suggestions = await endpoints.item.suggestNames(
          as(aliceId),
          list.id!,
          'ap',
        );

        expect(suggestions, ['Apple', 'Apricot']);
      });

      test("scoped to the list -- another list's history does not leak in", () async {
        final list = await aSharedList();
        final otherList = await endpoints.list.create(as(aliceId), 'Camping');
        await endpoints.item.add(as(aliceId), otherList.id!, 'Bread');

        expect(
          await endpoints.item.suggestNames(as(aliceId), list.id!, 'bread'),
          isEmpty,
        );
      });

      test('refuses a non-member', () async {
        final list = await aSharedList();
        await endpoints.item.add(as(aliceId), list.id!, 'Milk');

        await expectLater(
          endpoints.item.suggestNames(as(strangerId), list.id!, 'milk'),
          throwsA(isA<NotAMemberException>()),
        );
      });
    });
  });
}
