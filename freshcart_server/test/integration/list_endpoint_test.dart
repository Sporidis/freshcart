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

      expect(list.joinCode, hasLength(6));
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
        endpoints.list.join(as(bobId), 'ZZZZZZ'),
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
  });
}
