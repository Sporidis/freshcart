import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

import '../fakes/fake_repositories.dart';

void main() {
  group('StartLinkEmail', () {
    late FakeAuthRepository auth;
    late StartLinkEmail startLinkEmail;

    setUp(() {
      auth = FakeAuthRepository();
      startLinkEmail = StartLinkEmail(auth);
    });

    test('sends a code when the password is valid', () async {
      final result = await startLinkEmail(
        email: 'alex@example.com',
        password: 'correct horse',
      );

      expect(result, const Ok('request-1'));
      expect(auth.startLinkEmailCalls.single, 'alex@example.com');
    });

    test('sends no code for a password that breaks the rule', () async {
      // Otherwise the user would wait for a code, type it, and only then
      // hear the password is too short.
      final result = await startLinkEmail(
        email: 'alex@example.com',
        password: 'short',
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(auth.startLinkEmailCalls, isEmpty);
    });
  });

  group('LinkEmail', () {
    late FakeAuthRepository auth;
    late LinkEmail linkEmail;

    setUp(() {
      auth = FakeAuthRepository();
      linkEmail = LinkEmail(auth);
    });

    test('finishes with the request, code and password', () async {
      final result = await linkEmail(
        requestId: 'request-1',
        code: '12345678',
        password: 'correct horse',
      );

      expect(result.isOk, isTrue);
      expect(auth.finishLinkEmailCalls.single, (
        requestId: 'request-1',
        code: '12345678',
        password: 'correct horse',
      ));
    });

    test('refuses a password that breaks the rule, without a call', () async {
      final result = await linkEmail(
        requestId: 'request-1',
        code: '12345678',
        password: 'short',
      );

      expect(
        result.failureOrNull,
        const Failure.validation(
          ValidationIssue.tooShort(
            ValidatedInput.password,
            min: AuthUser.minPasswordLength,
          ),
        ),
      );
      expect(auth.finishLinkEmailCalls, isEmpty);
    });

    test('sends the password normalized, the form the server stores', () async {
      await linkEmail(
        requestId: 'request-1',
        code: '12345678',
        password: 'café au lait', // e + combining accent
      );

      expect(auth.finishLinkEmailCalls.single.password, 'café au lait');
    });

    test('surfaces a port failure unchanged', () async {
      auth.finishLinkEmailResult = const Err<AuthUser>(
        Failure.validation(
          ValidationIssue.invalidFormat(ValidatedInput.verificationCode),
        ),
      );

      final result = await linkEmail(
        requestId: 'request-1',
        code: '00000000',
        password: 'correct horse',
      );

      expect(result.failureOrNull, auth.finishLinkEmailResult!.failureOrNull);
    });
  });
}
