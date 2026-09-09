import 'package:freshcart_server/src/auth/auth_configuration.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  // withServerpod does not run the server's run(), so the auth providers have
  // to be initialised here with the same configuration production uses.
  setUpAll(
    () => AuthServices.set(
      tokenManagerBuilders: AuthConfiguration.tokenManagerBuilders,
      identityProviderBuilders: AuthConfiguration.identityProviderBuilders,
    ),
  );

  withServerpod('Given AccountEndpoint', (sessionBuilder, endpoints) {
    TestSessionBuilder as(String userId) => sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(userId, {}),
    );

    /// Creates a real auth user, as an anonymous sign-in would.
    ///
    /// A fabricated id is not enough here: linking writes a row with a foreign
    /// key onto the auth module's user table, so the user has to actually
    /// exist — which is precisely the relationship being tested.
    Future<String> anAnonymousUser() async {
      final session = sessionBuilder.build();
      final user = await AuthServices.instance.authUsers.create(session);
      return user.id.uuid;
    }

    test('a fresh account reports itself anonymous', () async {
      final alice = await anAnonymousUser();

      expect(
        await endpoints.account.linkedProviders(as(alice)),
        [LinkedProvider.anonymous],
      );
      expect((await endpoints.profile.me(as(alice))).isAnonymous, isTrue);
    });

    test(
      'linking email keeps the same user id and preserves their data',
      () async {
        // This is the claim decisions #6 rests on, so it is asserted rather than
        // assumed: create data anonymously, upgrade, and check it is all still
        // there under the same id.
        final alice = await anAnonymousUser();
        final list = await endpoints.list.create(as(alice), 'Groceries');
        await endpoints.item.add(as(alice), list.id!, 'Milk');

        await endpoints.account.linkEmail(
          as(alice),
          'alice@example.com',
          'correct horse battery staple',
        );

        final me = await endpoints.profile.me(as(alice));
        expect(me.userId, UuidValue.withValidation(alice));
        expect(me.isAnonymous, isFalse);

        final lists = await endpoints.list.myLists(as(alice));
        expect(lists.single.id, list.id);
        final items = await endpoints.item.byList(as(alice), list.id!);
        expect(items.single.name, 'Milk');
      },
    );

    test('linkedProviders reports email after linking', () async {
      final bob = await anAnonymousUser();

      await endpoints.account.linkEmail(
        as(bob),
        'bob@example.com',
        'correct horse battery staple',
      );

      expect(
        await endpoints.account.linkedProviders(as(bob)),
        contains(LinkedProvider.email),
      );
    });

    test('linking twice is refused', () async {
      final user = await anAnonymousUser();
      await endpoints.account.linkEmail(
        as(user),
        'twice@example.com',
        'correct horse battery staple',
      );

      await expectLater(
        endpoints.account.linkEmail(
          as(user),
          'other@example.com',
          'correct horse battery staple',
        ),
        throwsA(isA<AccountAlreadyLinkedException>()),
      );
    });

    test('an email already belonging to someone else is refused', () async {
      // Attaching it would be account takeover.
      final first = await anAnonymousUser();
      final second = await anAnonymousUser();
      await endpoints.account.linkEmail(
        as(first),
        'shared@example.com',
        'correct horse battery staple',
      );

      await expectLater(
        endpoints.account.linkEmail(
          as(second),
          'shared@example.com',
          'correct horse battery staple',
        ),
        throwsA(isA<EmailAlreadyInUseException>()),
      );
    });
  });
}
