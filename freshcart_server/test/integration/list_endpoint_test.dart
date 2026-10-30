import 'dart:typed_data';

import 'package:freshcart_domain/freshcart_domain.dart' as domain;
import 'package:freshcart_server/src/auth/auth_configuration.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import 'support/invite_code.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  /// Two distinct signed-in users. `authUserId` is the session's
  /// `userIdentifier` parsed as a UUID, so any valid UUID stands in for an
  /// account here.
  final aliceId = const Uuid().v4();
  final bobId = const Uuid().v4();

  // withServerpod does not run the server's run(); the members group below
  // creates real auth users, which needs the auth services set up the same
  // way production does (same as account_link_test).
  setUpAll(
    () => AuthServices.set(
      tokenManagerBuilders: AuthConfiguration.tokenManagerBuilders,
      identityProviderBuilders: AuthConfiguration.identityProviderBuilders,
    ),
  );

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

    group('invites', () {
      final carolId = const Uuid().v4();

      /// Moves [list]'s invite expiry to [expiresAt], standing in for time
      /// passing (or, with null, for a row from before invites expired).
      Future<void> setInviteExpiry(
        ShoppingList list,
        DateTime? expiresAt,
      ) async {
        final session = sessionBuilder.build();
        final row = await ShoppingList.db.findById(session, list.id!);
        await ShoppingList.db.updateRow(
          session,
          row!.copyWith(joinCodeExpiresAt: expiresAt),
        );
      }

      test('a new list has no join code until someone invites', () async {
        final list = await endpoints.list.create(as(aliceId), 'Groceries');

        expect(list.joinCode, isNull);
        expect(list.joinCodeExpiresAt, isNull);
      });

      test(
        'opening an invite issues a code from the unambiguous alphabet, '
        'valid for the invite lifetime',
        () async {
          final list = await endpoints.list.create(as(aliceId), 'Groceries');
          final before = DateTime.now().toUtc();

          final invited = await endpoints.list.openInvite(
            as(aliceId),
            list.id!,
          );

          expect(invited.joinCode, hasLength(5));
          // The domain excludes I, O, 0 and 1 so a spoken code is
          // unambiguous.
          expect(invited.joinCode, isNot(matches(RegExp('[IO01]'))));
          final lifetime = invited.joinCodeExpiresAt!.difference(before);
          expect(
            lifetime.inSeconds,
            closeTo(domain.ListInvite.lifetime.inSeconds, 60),
          );
        },
      );

      test('two lists never share a join code', () async {
        final first = await endpoints.list.create(as(aliceId), 'One');
        final second = await endpoints.list.create(as(aliceId), 'Two');

        expect(
          await endpoints.inviteCode(as(aliceId), first),
          isNot(await endpoints.inviteCode(as(aliceId), second)),
        );
      });

      test('an open invite is reused, by any member', () async {
        final list = await endpoints.list.create(as(aliceId), 'Groceries');
        final code = await endpoints.inviteCode(as(aliceId), list);
        await endpoints.list.join(as(bobId), code);

        expect(await endpoints.inviteCode(as(aliceId), list), code);
        expect(await endpoints.inviteCode(as(bobId), list), code);
      });

      test('a non-member cannot open an invite', () async {
        final list = await endpoints.list.create(as(aliceId), 'Groceries');

        await expectLater(
          endpoints.list.openInvite(as(bobId), list.id!),
          throwsA(isA<NotAMemberException>()),
        );
      });

      test('several people can join with the same code', () async {
        final list = await endpoints.list.create(as(aliceId), 'Groceries');
        final code = await endpoints.inviteCode(as(aliceId), list);

        await endpoints.list.join(as(bobId), code);
        final joined = await endpoints.list.join(as(carolId), code);

        expect(joined.members, hasLength(3));
      });

      test('an expired code is refused like one that never existed', () async {
        final list = await endpoints.list.create(as(aliceId), 'Groceries');
        final code = await endpoints.inviteCode(as(aliceId), list);
        await setInviteExpiry(
          list,
          DateTime.now().toUtc().subtract(const Duration(seconds: 1)),
        );

        await expectLater(
          endpoints.list.join(as(bobId), code),
          throwsA(isA<InvalidJoinCodeException>()),
        );
      });

      test('a code from before invites expired no longer works', () async {
        final list = await endpoints.list.create(as(aliceId), 'Groceries');
        final code = await endpoints.inviteCode(as(aliceId), list);
        await setInviteExpiry(list, null);

        await expectLater(
          endpoints.list.join(as(bobId), code),
          throwsA(isA<InvalidJoinCodeException>()),
        );
      });

      test(
        'an invite close to expiry is replaced, and the old code stops '
        'working',
        () async {
          final list = await endpoints.list.create(as(aliceId), 'Groceries');
          final oldCode = await endpoints.inviteCode(as(aliceId), list);
          // Still open, but with less left than is worth handing out.
          await setInviteExpiry(
            list,
            DateTime.now().toUtc().add(
              domain.ListInvite.minRemainingToReuse -
                  const Duration(minutes: 1),
            ),
          );

          final newCode = await endpoints.inviteCode(as(aliceId), list);

          expect(newCode, isNot(oldCode));
          await expectLater(
            endpoints.list.join(as(bobId), oldCode),
            throwsA(isA<InvalidJoinCodeException>()),
          );
          final joined = await endpoints.list.join(as(bobId), newCode);
          expect(joined.id, list.id);
        },
      );
    });

    test('myLists returns only lists the caller belongs to', () async {
      await endpoints.list.create(as(aliceId), 'Alice list');

      expect(await endpoints.list.myLists(as(aliceId)), hasLength(1));
      expect(await endpoints.list.myLists(as(bobId)), isEmpty);
    });

    test('join adds the caller as a plain member', () async {
      final list = await endpoints.list.create(as(aliceId), 'Groceries');

      final joined = await endpoints.list.join(
        as(bobId),
        await endpoints.inviteCode(as(aliceId), list),
      );

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
        '  ${(await endpoints.inviteCode(as(aliceId), list)).toLowerCase()} ',
      );

      expect(joined.id, list.id);
    });

    test('joining twice is a no-op rather than an error', () async {
      final list = await endpoints.list.create(as(aliceId), 'Groceries');

      await endpoints.list.join(
        as(bobId),
        await endpoints.inviteCode(as(aliceId), list),
      );
      final again = await endpoints.list.join(
        as(bobId),
        await endpoints.inviteCode(as(aliceId), list),
      );

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
      await endpoints.list.join(
        as(bobId),
        await endpoints.inviteCode(as(aliceId), list),
      );

      await expectLater(
        endpoints.list.rename(as(bobId), list.id!, 'Hijacked'),
        throwsA(isA<NotListOwnerException>()),
      );
    });

    test('leave removes the caller from the list', () async {
      final list = await endpoints.list.create(as(aliceId), 'Groceries');
      await endpoints.list.join(
        as(bobId),
        await endpoints.inviteCode(as(aliceId), list),
      );

      await endpoints.list.leave(as(bobId), list.id!);

      expect(await endpoints.list.myLists(as(bobId)), isEmpty);
      expect(await endpoints.list.myLists(as(aliceId)), hasLength(1));
    });

    test('delete removes the list for everyone on it', () async {
      final list = await endpoints.list.create(as(aliceId), 'Groceries');
      await endpoints.list.join(
        as(bobId),
        await endpoints.inviteCode(as(aliceId), list),
      );

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
      await endpoints.list.join(
        as(bobId),
        await endpoints.inviteCode(as(aliceId), list),
      );

      await expectLater(
        endpoints.list.delete(as(bobId), list.id!),
        throwsA(isA<NotListOwnerException>()),
      );
      expect(await endpoints.list.myLists(as(aliceId)), hasLength(1));
    });

    group('managing members', () {
      test('the owner can remove another member', () async {
        final list = await endpoints.list.create(as(aliceId), 'Groceries');
        await endpoints.list.join(
          as(bobId),
          await endpoints.inviteCode(as(aliceId), list),
        );

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
        await endpoints.list.join(
          as(bobId),
          await endpoints.inviteCode(as(aliceId), list),
        );

        await expectLater(
          endpoints.list.removeMember(
            as(bobId),
            list.id!,
            UuidValue.withValidation(aliceId),
          ),
          throwsA(isA<NotListOwnerException>()),
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
        await endpoints.list.join(
          as(bobId),
          await endpoints.inviteCode(as(aliceId), list),
        );

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
        await endpoints.list.join(
          as(bobId),
          await endpoints.inviteCode(as(aliceId), list),
        );
        await endpoints.list.transferOwnership(
          as(aliceId),
          list.id!,
          UuidValue.withValidation(bobId),
        );

        await expectLater(
          endpoints.list.delete(as(aliceId), list.id!),
          throwsA(isA<NotListOwnerException>()),
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

    group('members show who they are now, not who they were at join', () {
      ListMember memberIn(ShoppingList list, String userId) => list.members!
          .firstWhere((m) => m.userId == UuidValue.withValidation(userId));

      /// A real auth user. A made-up id is fine for lists, but a profile row
      /// has a foreign key onto the auth module's user table -- every real
      /// caller exists there, so these tests' callers have to as well.
      Future<String> aUser() async {
        final user = await AuthServices.instance.authUsers.create(
          sessionBuilder.build(),
        );
        return user.id.uuid;
      }

      test('a rename after joining shows on the list', () async {
        final aliceId = await aUser();
        final bobId = await aUser();
        await endpoints.profile.setDisplayName(as(bobId), 'Bob');
        final list = await endpoints.list.create(as(aliceId), 'Groceries');
        await endpoints.list.join(
          as(bobId),
          await endpoints.inviteCode(as(aliceId), list),
        );

        await endpoints.profile.setDisplayName(as(bobId), 'Robert');

        final read = await endpoints.list.byId(as(aliceId), list.id!);
        expect(memberIn(read, bobId).displayName, 'Robert');
      });

      test('an avatar colour picked after joining shows on the list', () async {
        final aliceId = await aUser();
        final list = await endpoints.list.create(as(aliceId), 'Groceries');

        await endpoints.profile.setAvatarColor(as(aliceId), 0xFF2456A6);

        final read = await endpoints.list.byId(as(aliceId), list.id!);
        expect(memberIn(read, aliceId).avatarColorArgb, 0xFF2456A6);
      });

      test('someone with no profile yet still gets a name', () async {
        final aliceId = await aUser();
        final list = await endpoints.list.create(as(aliceId), 'Groceries');

        expect(memberIn(list, aliceId).displayName, 'Someone');
      });

      test('a profile change is broadcast to everyone watching', () async {
        final aliceId = await aUser();
        final bobId = await aUser();
        final list = await endpoints.list.create(as(aliceId), 'Groceries');
        await endpoints.list.join(
          as(bobId),
          await endpoints.inviteCode(as(aliceId), list),
        );

        final events = <ShoppingList>[];
        final subscription = endpoints.list
            .watchList(as(aliceId), list.id!)
            .listen(events.add);
        addTearDown(subscription.cancel);
        await Future<void>.delayed(const Duration(milliseconds: 100));

        await endpoints.profile.setDisplayName(as(bobId), 'Robert');
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(events, isNotEmpty);
        expect(memberIn(events.last, bobId).displayName, 'Robert');
      });

      test('a new photo gets a new URL, so image caches cannot serve the '
          'old one', () async {
        final aliceId = await aUser();
        final list = await endpoints.list.create(as(aliceId), 'Groceries');
        final photo = ByteData.view(Uint8List.fromList([1, 2, 3]).buffer);

        await endpoints.profile.setAvatarPhoto(as(aliceId), photo);
        final first = memberIn(
          await endpoints.list.byId(as(aliceId), list.id!),
          aliceId,
        ).avatarPhotoUrl;
        await endpoints.profile.setAvatarPhoto(as(aliceId), photo);
        final second = memberIn(
          await endpoints.list.byId(as(aliceId), list.id!),
          aliceId,
        ).avatarPhotoUrl;

        expect(first, isNotNull);
        expect(second, isNotNull);
        expect(second, isNot(first));
      });
    });

    group('names follow the domain rules', () {
      test('create refuses a blank name and trims a good one', () async {
        await expectLater(
          endpoints.list.create(as(aliceId), '   '),
          throwsA(isA<ValidationException>()),
        );
        final list = await endpoints.list.create(as(aliceId), ' Groceries ');
        expect(list.name, 'Groceries');
      });

      test('rename refuses a blank name', () async {
        final list = await endpoints.list.create(as(aliceId), 'Groceries');
        await expectLater(
          endpoints.list.rename(as(aliceId), list.id!, '  '),
          throwsA(isA<ValidationException>()),
        );
      });

      test('a display name is refused when blank and stored trimmed', () async {
        // A profile row needs a real auth user (see the members group).
        final userId = (await AuthServices.instance.authUsers.create(
          sessionBuilder.build(),
        )).id.uuid;
        await expectLater(
          endpoints.profile.setDisplayName(as(userId), '   '),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.input,
              'input',
              'displayName',
            ),
          ),
        );
        final profile = await endpoints.profile.setDisplayName(
          as(userId),
          ' Alice ',
        );
        expect(profile.displayName, 'Alice');
      });
    });
  });

  // The live streams check membership for every message, in their own
  // database call, while the change that triggered the message is still
  // running. The default rollback mode allows only one database call at a
  // time, so these tests run without it. Each test makes its own list with
  // fresh user ids, so leftover rows don't affect other tests.
  withServerpod(
    'Given ListEndpoint live streams',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      TestSessionBuilder as(String userId) => sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(userId, {}),
      );

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

          await endpoints.list.join(
            as(bobId),
            await endpoints.inviteCode(as(aliceId), list),
          );
          await letSubscriptionSettle();

          expect(events, isNotEmpty);
          expect(events.last.members, hasLength(2));
        });

        test('emits the drop when a member leaves', () async {
          final list = await endpoints.list.create(as(aliceId), 'Groceries');
          await endpoints.list.join(
            as(bobId),
            await endpoints.inviteCode(as(aliceId), list),
          );

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
            await endpoints.list.join(
              as(bobId),
              await endpoints.inviteCode(as(aliceId), list),
            );

            final events = <ShoppingList>[];
            final subscription = endpoints.list
                .watchList(as(aliceId), list.id!)
                .listen(events.add);
            addTearDown(subscription.cancel);
            await letSubscriptionSettle();

            // Bob is already a member; joining again is a documented no-op.
            await endpoints.list.join(
              as(bobId),
              await endpoints.inviteCode(as(aliceId), list),
            );
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
        test('a removed member\'s stream ends, without the new member '
            'list', () async {
          final list = await endpoints.list.create(as(aliceId), 'Groceries');
          await endpoints.list.join(
            as(bobId),
            await endpoints.inviteCode(as(aliceId), list),
          );

          final events = <ShoppingList>[];
          var ended = false;
          final subscription = endpoints.list
              .watchList(as(bobId), list.id!)
              .listen(events.add, onDone: () => ended = true);
          addTearDown(subscription.cancel);
          await letSubscriptionSettle();

          await endpoints.list.removeMember(
            as(aliceId),
            list.id!,
            UuidValue.withValidation(bobId),
          );
          await endpoints.list.rename(as(aliceId), list.id!, 'Secret plans');
          await letSubscriptionSettle();

          expect(ended, isTrue);
          expect(events, isEmpty);
        });

        test('a removed member\'s item stream ends', () async {
          final list = await endpoints.list.create(as(aliceId), 'Groceries');
          await endpoints.list.join(
            as(bobId),
            await endpoints.inviteCode(as(aliceId), list),
          );

          final events = <ItemChange>[];
          var ended = false;
          final subscription = endpoints.item
              .watchList(as(bobId), list.id!)
              .listen(events.add, onDone: () => ended = true);
          addTearDown(subscription.cancel);
          await letSubscriptionSettle();

          await endpoints.list.removeMember(
            as(aliceId),
            list.id!,
            UuidValue.withValidation(bobId),
          );
          await endpoints.item.add(as(aliceId), list.id!, 'Milk');
          await letSubscriptionSettle();

          expect(ended, isTrue);
          expect(events, isEmpty);
        });
      });
    },
  );
}
