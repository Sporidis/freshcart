import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

import '../fakes/fake_repositories.dart';

void main() {
  group('LinkEmail', () {
    late FakeAuthRepository auth;
    late LinkEmail linkEmail;

    setUp(() {
      auth = FakeAuthRepository();
      linkEmail = LinkEmail(auth);
    });

    test('links a valid email and password', () async {
      final result = await linkEmail(
        email: 'alex@example.com',
        password: 'correct horse',
      );

      expect(result.isOk, isTrue);
      expect(auth.linkEmailCalls.single, (
        email: 'alex@example.com',
        password: 'correct horse',
      ));
    });

    test('refuses a password that breaks the rule, without a call', () async {
      final result = await linkEmail(
        email: 'alex@example.com',
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
      expect(auth.linkEmailCalls, isEmpty);
    });

    test('sends the password normalized, the form the server stores', () async {
      await linkEmail(
        email: 'alex@example.com',
        password: 'café au lait', // e + combining accent
      );

      expect(auth.linkEmailCalls.single.password, 'café au lait');
    });

    test('surfaces a port failure unchanged', () async {
      auth.linkEmailResult = const Err<AuthUser>(
        Failure.validation(ValidationIssue.alreadyInUse(ValidatedInput.email)),
      );

      final result = await linkEmail(
        email: 'taken@example.com',
        password: 'correct horse',
      );

      expect(result.failureOrNull, auth.linkEmailResult!.failureOrNull);
    });
  });
}
