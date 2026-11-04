import 'package:freshcart_server/src/auth/business/anonymous_signup_limit.dart';
import 'package:serverpod_auth_idp_server/providers/anonymous.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given AnonymousSignupLimit', (sessionBuilder, endpoints) {
    Future<void> signUp(String ip, int times) async {
      final session = sessionBuilder.build();
      for (var i = 0; i < times; i++) {
        await AnonymousSignupLimit.requireUnderLimit(session, ip);
      }
    }

    test('one address gets the limit, then is refused', () async {
      await signUp('203.0.113.7', AnonymousSignupLimit.maxPerIp);

      await expectLater(
        signUp('203.0.113.7', 1),
        throwsA(isA<AnonymousAccountBlockedException>()),
      );
    });

    test('one address reaching the limit leaves others alone', () async {
      await signUp('203.0.113.8', AnonymousSignupLimit.maxPerIp);

      await expectLater(signUp('203.0.113.9', 1), completes);
    });
  });
}
