import 'package:freshcart_server/src/auth/auth_configuration.dart';
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

  withServerpod('Given ProfileEndpoint', (sessionBuilder, endpoints) {
    TestSessionBuilder as(String userId) => sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(userId, {}),
    );

    Future<String> anAnonymousUser() async {
      final user = await AuthServices.instance.authUsers.create(
        sessionBuilder.build(),
      );
      return user.id.uuid;
    }

    test(
      'a new account has no profile, so it still needs onboarding',
      () async {
        final alice = await anAnonymousUser();

        expect((await endpoints.profile.me(as(alice))).hasProfile, isFalse);
      },
    );

    test('setting a name creates the profile', () async {
      final alice = await anAnonymousUser();

      await endpoints.profile.setDisplayName(as(alice), 'Alice');

      expect((await endpoints.profile.me(as(alice))).hasProfile, isTrue);
    });
  });
}
