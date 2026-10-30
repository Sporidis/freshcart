import 'package:freshcart_server/src/auth/auth_configuration.dart';
import 'package:freshcart_server/src/auth/business/account_retention.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import 'support/invite_code.dart';
import 'test_tools/serverpod_test_tools.dart';

/// Inactive anonymous accounts are deleted once nobody can sign into them
/// any more (5.4). Time is moved forward through the `now` parameter
/// instead of waiting a year.
void main() {
  setUpAll(
    () => AuthServices.set(
      tokenManagerBuilders: AuthConfiguration.tokenManagerBuilders,
      identityProviderBuilders: AuthConfiguration.identityProviderBuilders,
    ),
  );

  withServerpod('Given AccountRetention', (sessionBuilder, endpoints) {
    TestSessionBuilder as(UuidValue userId) => sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(
        userId.uuid,
        {},
      ),
    );

    Session session() => sessionBuilder.build();

    /// A year and a day from now: every session made today has expired.
    final later = DateTime.now().toUtc().add(
      AccountRetention.sessionLifetime + const Duration(days: 1),
    );

    Future<UuidValue> anAccount() async =>
        (await AuthServices.instance.authUsers.create(session())).id;

    /// Gives [userId] a session, last used at [at].
    Future<void> usedAt(UuidValue userId, DateTime at) async {
      await AuthServices.getTokenManager<JwtTokenManager>().jwt.createTokens(
        session(),
        authUserId: userId,
        method: 'anonymous',
      );
      await RefreshToken.db.updateWhere(
        session(),
        where: (t) => t.authUserId.equals(userId),
        columnValues: (t) => [t.lastUpdatedAt(at)],
      );
    }

    Future<bool> exists(UuidValue userId) async =>
        (await AuthServices.instance.authUsers.list(
          session(),
        )).any((u) => u.id == userId);

    test('an anonymous account nobody can sign into is deleted', () async {
      final quiet = await anAccount();
      await usedAt(quiet, DateTime.now().toUtc());

      final deleted = await AccountRetention.deleteUnreachableAnonymousAccounts(
        session(),
        now: later,
      );

      // At least this one (the test database also keeps accounts other
      // test files left behind).
      expect(deleted, greaterThanOrEqualTo(1));
      expect(await exists(quiet), isFalse);
    });

    test('an anonymous account used within the lifetime stays', () async {
      final active = await anAccount();
      // Last used just before "later": still a valid session then.
      await usedAt(active, later.subtract(const Duration(days: 1)));

      await AccountRetention.deleteUnreachableAnonymousAccounts(
        session(),
        now: later,
      );

      expect(await exists(active), isTrue);
    });

    test('a quiet account with an email login stays: it can sign in', () async {
      final linked = await anAccount();
      await EmailAccount.db.insertRow(
        session(),
        EmailAccount(
          authUserId: linked,
          email: 'quiet-${linked.uuid}@example.test',
          passwordHash: 'not-a-real-hash',
        ),
      );

      await AccountRetention.deleteUnreachableAnonymousAccounts(
        session(),
        now: later,
      );

      expect(await exists(linked), isTrue);
    });

    test('a young account is never a candidate', () async {
      final fresh = await anAccount();

      // Today: it was created less than a lifetime ago.
      await AccountRetention.deleteUnreachableAnonymousAccounts(session());

      expect(await exists(fresh), isTrue);
    });

    test('a shared list they owned goes to the others, like a deletion '
        'by hand', () async {
      final quiet = await anAccount();
      final active = await anAccount();
      await usedAt(active, later.subtract(const Duration(days: 1)));
      final list = await endpoints.list.create(as(quiet), 'Household');
      await endpoints.list.join(
        as(active),
        await endpoints.inviteCode(as(quiet), list),
      );

      await AccountRetention.deleteUnreachableAnonymousAccounts(
        session(),
        now: later,
      );

      final after = await endpoints.list.byId(as(active), list.id!);
      expect(after.ownerId, active);
    });
  });
}
