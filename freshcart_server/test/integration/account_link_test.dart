import 'package:freshcart_server/src/auth/auth_configuration.dart';
import 'package:freshcart_server/src/auth/business/email_message.dart';
import 'package:freshcart_server/src/auth/business/email_sender.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

/// Keeps the emails instead of sending them, so a test can read the code.
class _CapturingEmailSender implements EmailSender {
  final List<EmailMessage> sent = [];

  @override
  Future<void> send(Session session, EmailMessage message) async =>
      sent.add(message);

  /// The code in the last email to [to]. The code is the body's last word.
  String lastCodeTo(String to) =>
      sent.lastWhere((m) => m.to == to).body.split(' ').last;
}

/// A fresh address per call. Linking runs Serverpod's own transactions,
/// which the default rollback mode doesn't allow, so these tests keep their
/// rows and must not collide.
String _uniqueEmail() => '${const Uuid().v4()}@example.com';

void main() {
  // withServerpod does not run the server's run(), so the auth providers have
  // to be initialised here with the same configuration production uses.
  setUpAll(
    () => AuthServices.set(
      tokenManagerBuilders: AuthConfiguration.tokenManagerBuilders,
      identityProviderBuilders: AuthConfiguration.identityProviderBuilders,
    ),
  );

  late _CapturingEmailSender mailbox;
  setUp(
    () => AuthConfiguration.emailSender = mailbox = _CapturingEmailSender(),
  );
  tearDown(() => AuthConfiguration.emailSender = const LoggingEmailSender());

  withServerpod(
    'Given AccountEndpoint',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      TestSessionBuilder as(String userId) => sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(userId, {}),
      );

      /// Creates a real auth user, as an anonymous sign-in would.
      ///
      /// A fabricated id is not enough here: linking writes a row with a
      /// foreign key onto the auth module's user table, so the user has to
      /// actually exist — which is precisely the relationship being tested.
      Future<String> anAnonymousUser() async {
        final user = await AuthServices.instance.authUsers.create(
          sessionBuilder.build(),
        );
        return user.id.uuid;
      }

      /// The first two steps, as the app runs them: start, then verify the
      /// code from the email. Returns the token that finishes the link.
      Future<String> verifiedToken(String email) async {
        final requestId = await endpoints.emailIdp.startRegistration(
          sessionBuilder,
          email: email,
        );
        return endpoints.emailIdp.verifyRegistrationCode(
          sessionBuilder,
          accountRequestId: requestId,
          verificationCode: mailbox.lastCodeTo(email),
        );
      }

      /// All three steps for [userId].
      Future<void> link(
        String userId,
        String email, {
        String password = 'correct horse battery staple',
      }) async => endpoints.account.finishLinkEmail(
        as(userId),
        await verifiedToken(email),
        password,
      );

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
          // This is the claim decisions #6 rests on, so it is asserted rather
          // than assumed: create data anonymously, upgrade, and check it is
          // all still there under the same id.
          final alice = await anAnonymousUser();
          final list = await endpoints.list.create(as(alice), 'Groceries');
          await endpoints.item.add(as(alice), list.id!, 'Milk');

          await link(alice, _uniqueEmail());

          final me = await endpoints.profile.me(as(alice));
          expect(me.userId, UuidValue.withValidation(alice));
          expect(me.isAnonymous, isFalse);
          expect(
            await endpoints.account.linkedProviders(as(alice)),
            contains(LinkedProvider.email),
          );

          final lists = await endpoints.list.myLists(as(alice));
          expect(lists.single.id, list.id);
          final items = await endpoints.item.byList(as(alice), list.id!);
          expect(items.single.name, 'Milk');
        },
      );

      test('the user Serverpod creates along the way is removed', () async {
        // Finishing a registration makes a new auth user; the merge has to
        // delete it, or every link would leave an empty account behind.
        final alice = await anAnonymousUser();
        final token = await verifiedToken(_uniqueEmail());
        final session = sessionBuilder.build();
        final before = await AuthUser.db.count(session);

        await endpoints.account.finishLinkEmail(
          as(alice),
          token,
          'correct horse battery staple',
        );

        expect(await AuthUser.db.count(session), before);
      });

      test('a token that was never verified is refused', () async {
        final user = await anAnonymousUser();

        await expectLater(
          endpoints.account.finishLinkEmail(
            as(user),
            'not-a-real-token',
            'correct horse battery staple',
          ),
          throwsA(isA<EmailAccountRequestException>()),
        );
        expect(
          await endpoints.account.linkedProviders(as(user)),
          [LinkedProvider.anonymous],
        );
      });

      test('a token only works once', () async {
        // Otherwise one verified inbox could be attached to several
        // accounts by replaying the token.
        final first = await anAnonymousUser();
        final second = await anAnonymousUser();
        final token = await verifiedToken(_uniqueEmail());
        await endpoints.account.finishLinkEmail(
          as(first),
          token,
          'correct horse battery staple',
        );

        await expectLater(
          endpoints.account.finishLinkEmail(
            as(second),
            token,
            'correct horse battery staple',
          ),
          throwsA(isA<EmailAccountRequestException>()),
        );
      });

      test('linking twice is refused', () async {
        final user = await anAnonymousUser();
        await link(user, _uniqueEmail());

        await expectLater(
          link(user, _uniqueEmail()),
          throwsA(isA<AccountAlreadyLinkedException>()),
        );
      });

      test(
        'an email that already has an account gets no code, and the caller '
        'is not told why',
        () async {
          // The old linkEmail answered "email in use", which told anyone
          // with an anonymous account who has a FreshCart login.
          final email = _uniqueEmail();
          await link(await anAnonymousUser(), email);
          mailbox.sent.clear();

          final requestId = await endpoints.emailIdp.startRegistration(
            sessionBuilder,
            email: email,
          );

          expect(requestId, isA<UuidValue>());
          expect(mailbox.sent, isEmpty);
        },
      );

      test('a password that breaks the domain rule is refused', () async {
        final user = await anAnonymousUser();

        await expectLater(
          link(user, _uniqueEmail(), password: 'short'),
          throwsA(isA<ValidationException>()),
        );
        expect(
          await endpoints.account.linkedProviders(as(user)),
          [LinkedProvider.anonymous],
        );
      });

      test('logging in works however the keyboard types "é"', () async {
        final user = await anAnonymousUser();
        final email = _uniqueEmail();
        await link(user, email, password: 'café au lait'); // é as one

        final success = await endpoints.emailIdp.login(
          sessionBuilder,
          email: email,
          password: 'café au lait', // e + combining accent
        );

        expect(success.authUserId, UuidValue.withValidation(user));
      });
    },
  );
}
