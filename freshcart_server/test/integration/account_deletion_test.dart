import 'dart:typed_data';

import 'package:freshcart_server/src/auth/auth_configuration.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import 'support/invite_code.dart';
import 'test_tools/serverpod_test_tools.dart';

/// Deleting an account, as decided in decisions.md #119: everything about
/// the person goes, the household's shared lists stay.
void main() {
  setUpAll(
    () => AuthServices.set(
      tokenManagerBuilders: AuthConfiguration.tokenManagerBuilders,
      identityProviderBuilders: AuthConfiguration.identityProviderBuilders,
    ),
  );

  withServerpod('Given AccountEndpoint.deleteAccount', (
    sessionBuilder,
    endpoints,
  ) {
    TestSessionBuilder as(String userId) => sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(userId, {}),
    );

    /// A real auth user: deleting one needs it to exist.
    Future<String> aUser() async =>
        (await AuthServices.instance.authUsers.create(
          sessionBuilder.build(),
        )).id.uuid;

    UuidValue uuid(String id) => UuidValue.withValidation(id);

    test('everything about the person is gone', () async {
      final alice = await aUser();
      await endpoints.profile.setDisplayName(as(alice), 'Alice');
      final list = await endpoints.list.create(as(alice), 'Groceries');
      await endpoints.notification.registerDevice(
        as(alice),
        'token-alice',
        DevicePlatform.android,
      );
      await endpoints.notification.setMemberJoinedEnabled(as(alice), false);
      await endpoints.notification.setListMuted(as(alice), list.id!, true);

      await endpoints.account.deleteAccount(as(alice));

      final session = sessionBuilder.build();
      final id = uuid(alice);
      expect(
        (await AuthServices.instance.authUsers.list(session)).map((u) => u.id),
        isNot(contains(id)),
      );
      expect(
        await MemberProfile.db.count(
          session,
          where: (t) => t.authUserId.equals(id),
        ),
        0,
      );
      expect(
        await DeviceToken.db.count(
          session,
          where: (t) => t.ownerId.equals(id),
        ),
        0,
      );
      expect(
        await NotificationPreferences.db.count(
          session,
          where: (t) => t.userId.equals(id),
        ),
        0,
      );
      expect(
        await ListMute.db.count(session, where: (t) => t.userId.equals(id)),
        0,
      );
      expect(
        await ListMember.db.count(session, where: (t) => t.userId.equals(id)),
        0,
      );
    });

    test('their avatar photo file is deleted too', () async {
      final alice = await aUser();
      final photo = ByteData.view(Uint8List.fromList([1, 2, 3]).buffer);
      await endpoints.profile.setAvatarPhoto(as(alice), photo);
      final session = sessionBuilder.build();
      final path = (await MemberProfile.db.findFirstRow(
        session,
        where: (t) => t.authUserId.equals(uuid(alice)),
      ))!.avatarPhotoPath!;

      await endpoints.account.deleteAccount(as(alice));

      expect(
        await session.storage.fileExists(storageId: 'public', path: path),
        isFalse,
      );
    });

    test('a list only they are on is deleted, with its items', () async {
      final alice = await aUser();
      final list = await endpoints.list.create(as(alice), 'Mine');
      await endpoints.item.add(as(alice), list.id!, 'Milk');

      await endpoints.account.deleteAccount(as(alice));

      final session = sessionBuilder.build();
      expect(await ShoppingList.db.findById(session, list.id!), isNull);
      expect(
        await ShoppingItem.db.count(
          session,
          where: (t) => t.listId.equals(list.id!),
        ),
        0,
      );
    });

    test(
      'a shared list they own goes to the member who joined earliest',
      () async {
        final alice = await aUser();
        final bob = await aUser();
        final carol = await aUser();
        final list = await endpoints.list.create(as(alice), 'Household');
        final code = await endpoints.inviteCode(as(alice), list);
        await endpoints.list.join(as(bob), code);
        await endpoints.list.join(as(carol), code);

        await endpoints.account.deleteAccount(as(alice));

        final after = await endpoints.list.byId(as(carol), list.id!);
        expect(after.ownerId, uuid(bob));
        final roles = {for (final m in after.members!) m.userId: m.role};
        expect(roles, {
          uuid(bob): MemberRole.owner,
          uuid(carol): MemberRole.member,
        });
      },
    );

    test('their items on a shared list stay, for the others', () async {
      final alice = await aUser();
      final bob = await aUser();
      final list = await endpoints.list.create(as(alice), 'Household');
      await endpoints.list.join(
        as(bob),
        await endpoints.inviteCode(as(alice), list),
      );
      await endpoints.item.add(as(bob), list.id!, 'Bread');

      await endpoints.account.deleteAccount(as(bob));

      final items = await endpoints.item.byList(as(alice), list.id!);
      expect(items.single.name, 'Bread');
      // Their id stays, but points at no one any more (no profile, no
      // login), so it no longer identifies a person.
      expect(items.single.addedBy, uuid(bob));
      final after = await endpoints.list.byId(as(alice), list.id!);
      expect(after.members!.map((m) => m.userId), [uuid(alice)]);
    });
  });
}
