import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  /// Two distinct signed-in users. `authUserId` is the session's
  /// `userIdentifier` parsed as a UUID, so any valid UUID stands in for an
  /// account here.
  final aliceId = const Uuid().v4();
  final bobId = const Uuid().v4();

  withServerpod('Given ListEndpoint', (sessionBuilder, endpoints) {
    TestSessionBuilder as(String userId) => sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(userId, {}),
    );

    test(
      'create returns a list owned by the caller, with them as a member',
      () async {
        final list = await endpoints.list.create(as(aliceId), 'Groceries');

        expect(list.name, 'Groceries');
        expect(list.ownerId, UuidValue.withValidation(aliceId));
        expect(list.members, hasLength(1));
        expect(list.members!.single.role, MemberRole.owner);
      },
    );

    test('create issues a join code from the unambiguous alphabet', () async {
      final list = await endpoints.list.create(as(aliceId), 'Groceries');

      expect(list.joinCode, hasLength(5));
      // The domain excludes I, O, 0 and 1 so a spoken code is unambiguous.
      expect(list.joinCode, isNot(matches(RegExp('[IO01]'))));
    });

    test('two lists never share a join code', () async {
      final first = await endpoints.list.create(as(aliceId), 'One');
      final second = await endpoints.list.create(as(aliceId), 'Two');

      expect(first.joinCode, isNot(second.joinCode));
    });

    test('myLists returns only lists the caller belongs to', () async {
      await endpoints.list.create(as(aliceId), 'Alice list');

      expect(await endpoints.list.myLists(as(aliceId)), hasLength(1));
      expect(await endpoints.list.myLists(as(bobId)), isEmpty);
    });

    test('join adds the caller as a plain member', () async {
      final list = await endpoints.list.create(as(aliceId), 'Groceries');

      final joined = await endpoints.list.join(as(bobId), list.joinCode);

      expect(joined.id, list.id);
      expect(joined.members, hasLength(2));
      final bob = joined.members!.firstWhere(
        (m) => m.userId == UuidValue.withValidation(bobId),
      );
      expect(bob.role, MemberRole.member);
    });

    test('join accepts a lower-case, spaced code', () async {
      final list = await endpoints.list.create(as(aliceId), 'Groceries');

      final joined = await endpoints.list.join(
        as(bobId),
        '  ${list.joinCode.toLowerCase()} ',
      );

      expect(joined.id, list.id);
    });

    test('joining twice is a no-op rather than an error', () async {
      final list = await endpoints.list.create(as(aliceId), 'Groceries');

      await endpoints.list.join(as(bobId), list.joinCode);
      final again = await endpoints.list.join(as(bobId), list.joinCode);

      expect(again.members, hasLength(2));
    });

    test('join rejects a malformed code', () async {
      await expectLater(
        endpoints.list.join(as(bobId), 'nope'),
        throwsA(isA<InvalidJoinCodeException>()),
      );
    });

    test('join rejects a well-formed code that matches nothing', () async {
      await expectLater(
        endpoints.list.join(as(bobId), 'ZZZZZ'),
        throwsA(isA<InvalidJoinCodeException>()),
      );
    });

    test('byId refuses a caller who is not a member', () async {
      final list = await endpoints.list.create(as(aliceId), 'Groceries');

      await expectLater(
        endpoints.list.byId(as(bobId), list.id!),
        throwsA(isA<NotAMemberException>()),
      );
    });

    test('byId reports a missing list as not found', () async {
      await expectLater(
        endpoints.list.byId(
          as(aliceId),
          UuidValue.withValidation(const Uuid().v4()),
        ),
        throwsA(isA<ListNotFoundException>()),
      );
    });

    test('rename is allowed for the owner', () async {
      final list = await endpoints.list.create(as(aliceId), 'Groceries');

      final renamed = await endpoints.list.rename(
        as(aliceId),
        list.id!,
        'Shop',
      );

      expect(renamed.name, 'Shop');
    });

    test('rename is refused for a non-owner member', () async {
      final list = await endpoints.list.create(as(aliceId), 'Groceries');
      await endpoints.list.join(as(bobId), list.joinCode);

      await expectLater(
        endpoints.list.rename(as(bobId), list.id!, 'Hijacked'),
        throwsA(isA<NotAMemberException>()),
      );
    });

    test('leave removes the caller from the list', () async {
      final list = await endpoints.list.create(as(aliceId), 'Groceries');
      await endpoints.list.join(as(bobId), list.joinCode);

      await endpoints.list.leave(as(bobId), list.id!);

      expect(await endpoints.list.myLists(as(bobId)), isEmpty);
      expect(await endpoints.list.myLists(as(aliceId)), hasLength(1));
    });

    test('delete removes the list for everyone on it', () async {
      final list = await endpoints.list.create(as(aliceId), 'Groceries');
      await endpoints.list.join(as(bobId), list.joinCode);

      await endpoints.list.delete(as(aliceId), list.id!);

      expect(await endpoints.list.myLists(as(aliceId)), isEmpty);
      expect(
        await endpoints.list.myLists(as(bobId)),
        isEmpty,
        reason: 'deleting ends the list for the household, not just the owner',
      );
    });

    test('delete takes the items and shops with it', () async {
      final list = await endpoints.list.create(as(aliceId), 'Groceries');
      final shop = await endpoints.shop.create(
        as(aliceId),
        list.id!,
        'Colruyt',
        0xFF2E9E5B,
      );
      await endpoints.item.add(as(aliceId), list.id!, 'Milk', shopId: shop.id);

      await endpoints.list.delete(as(aliceId), list.id!);

      // The list is gone, so its children must be too -- reading them back
      // now reports the list itself missing rather than an empty collection.
      await expectLater(
        endpoints.item.byList(as(aliceId), list.id!),
        throwsA(isA<NotAMemberException>()),
      );
    });

    test('a member cannot delete the list, only leave it', () async {
      final list = await endpoints.list.create(as(aliceId), 'Groceries');
      await endpoints.list.join(as(bobId), list.joinCode);

      await expectLater(
        endpoints.list.delete(as(bobId), list.id!),
        throwsA(isA<NotAMemberException>()),
      );
      expect(await endpoints.list.myLists(as(aliceId)), hasLength(1));
    });

    group('managing members', () {
      test('the owner can remove another member', () async {
        final list = await endpoints.list.create(as(aliceId), 'Groceries');
        await endpoints.list.join(as(bobId), list.joinCode);

        await endpoints.list.removeMember(
          as(aliceId),
          list.id!,
          UuidValue.withValidation(bobId),
        );

        expect(await endpoints.list.myLists(as(bobId)), isEmpty);
        expect(await endpoints.list.myLists(as(aliceId)), hasLength(1));
      });

      test('a member cannot remove anyone', () async {
        final list = await endpoints.list.create(as(aliceId), 'Groceries');
        await endpoints.list.join(as(bobId), list.joinCode);

        await expectLater(
          endpoints.list.removeMember(
            as(bobId),
            list.id!,
            UuidValue.withValidation(aliceId),
          ),
          throwsA(isA<NotAMemberException>()),
        );
      });

      test('the owner cannot remove themselves', () async {
        final list = await endpoints.list.create(as(aliceId), 'Groceries');

        await expectLater(
          endpoints.list.removeMember(
            as(aliceId),
            list.id!,
            UuidValue.withValidation(aliceId),
          ),
          throwsA(isA<NotAMemberException>()),
          reason: 'that would leave the list ownerless; transfer or delete',
        );
      });

      test('ownership transfers, and swaps both roles', () async {
        final list = await endpoints.list.create(as(aliceId), 'Groceries');
        await endpoints.list.join(as(bobId), list.joinCode);

        final after = await endpoints.list.transferOwnership(
          as(aliceId),
          list.id!,
          UuidValue.withValidation(bobId),
        );

        expect(after.ownerId, UuidValue.withValidation(bobId));
        final roles = {
          for (final m in after.members!) m.userId: m.role,
        };
        expect(roles[UuidValue.withValidation(bobId)], MemberRole.owner);
        expect(
          roles[UuidValue.withValidation(aliceId)],
          MemberRole.member,
          reason: 'a list with two owners is worse than one that never moved',
        );
      });

      test('the new owner can then delete, and the old one cannot', () async {
        final list = await endpoints.list.create(as(aliceId), 'Groceries');
        await endpoints.list.join(as(bobId), list.joinCode);
        await endpoints.list.transferOwnership(
          as(aliceId),
          list.id!,
          UuidValue.withValidation(bobId),
        );

        await expectLater(
          endpoints.list.delete(as(aliceId), list.id!),
          throwsA(isA<NotAMemberException>()),
        );
        await endpoints.list.delete(as(bobId), list.id!);
        expect(await endpoints.list.myLists(as(bobId)), isEmpty);
      });

      test('ownership cannot be given to a non-member', () async {
        final list = await endpoints.list.create(as(aliceId), 'Groceries');

        await expectLater(
          endpoints.list.transferOwnership(
            as(aliceId),
            list.id!,
            UuidValue.withValidation(bobId),
          ),
          throwsA(isA<NotAMemberException>()),
        );
      });
    });

    group('watchList', () {
      // MessageCentral.addListener runs synchronously, but the endpoint method
      // does one DB round trip (the membership check) before reaching it, and
      // the generated stream is lazy — it does not start running until
      // something subscribes. A short real delay after subscribing gives that
      // round trip time to finish before the mutation that should be observed.
      Future<void> letSubscriptionSettle() =>
          Future<void>.delayed(const Duration(milliseconds: 100));

      test('emits the updated list when someone renames it', () async {
        final list = await endpoints.list.create(as(aliceId), 'Groceries');

        final events = <ShoppingList>[];
        final subscription = endpoints.list
            .watchList(as(aliceId), list.id!)
            .listen(events.add);
        addTearDown(subscription.cancel);
        await letSubscriptionSettle();

        await endpoints.list.rename(as(aliceId), list.id!, 'Weekend shop');
        await letSubscriptionSettle();

        expect(events, isNotEmpty);
        expect(events.last.name, 'Weekend shop');
      });

      test('emits the updated member list when someone joins', () async {
        final list = await endpoints.list.create(as(aliceId), 'Groceries');

        final events = <ShoppingList>[];
        final subscription = endpoints.list
            .watchList(as(aliceId), list.id!)
            .listen(events.add);
        addTearDown(subscription.cancel);
        await letSubscriptionSettle();

        await endpoints.list.join(as(bobId), list.joinCode);
        await letSubscriptionSettle();

        expect(events, isNotEmpty);
        expect(events.last.members, hasLength(2));
      });

      test('emits the drop when a member leaves', () async {
        final list = await endpoints.list.create(as(aliceId), 'Groceries');
        await endpoints.list.join(as(bobId), list.joinCode);

        final events = <ShoppingList>[];
        final subscription = endpoints.list
            .watchList(as(aliceId), list.id!)
            .listen(events.add);
        addTearDown(subscription.cancel);
        await letSubscriptionSettle();

        await endpoints.list.leave(as(bobId), list.id!);
        await letSubscriptionSettle();

        expect(events, isNotEmpty);
        expect(events.last.members, hasLength(1));
      });

      test(
        're-tapping a join link does not emit a duplicate notification',
        () async {
          final list = await endpoints.list.create(as(aliceId), 'Groceries');
          await endpoints.list.join(as(bobId), list.joinCode);

          final events = <ShoppingList>[];
          final subscription = endpoints.list
              .watchList(as(aliceId), list.id!)
              .listen(events.add);
          addTearDown(subscription.cancel);
          await letSubscriptionSettle();

          // Bob is already a member; joining again is a documented no-op.
          await endpoints.list.join(as(bobId), list.joinCode);
          await letSubscriptionSettle();

          expect(
            events,
            isEmpty,
            reason: 'a no-op join must not wake every other open client',
          );
        },
      );

      test('a non-member cannot open the stream', () async {
        final list = await endpoints.list.create(as(aliceId), 'Groceries');

        await expectLater(
          endpoints.list
              .watchList(as(bobId), list.id!)
              .listen((_) {})
              .asFuture<void>(),
          throwsA(isA<NotAMemberException>()),
        );
      });
    });
  });
}
