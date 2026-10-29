import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

void main() {
  group('AuthUser.validatePassword', () {
    ValidationIssue? issueFor(String password) =>
        switch (AuthUser.validatePassword(password)) {
          Ok() => null,
          Err(failure: ValidationFailure(:final issue)) => issue,
          Err(:final failure) => fail('unexpected failure $failure'),
        };

    test('accepts a password of the minimum length, unchanged', () {
      expect(AuthUser.validatePassword('12345678'), const Ok('12345678'));
    });

    test('an empty password is missing, not too short', () {
      expect(
        issueFor(''),
        const ValidationIssue.missing(ValidatedInput.password),
      );
    });

    test('refuses one character below the minimum', () {
      expect(
        issueFor('1234567'),
        const ValidationIssue.tooShort(
          ValidatedInput.password,
          min: AuthUser.minPasswordLength,
        ),
      );
    });

    test('accepts the maximum length, refuses one more', () {
      expect(issueFor('a' * AuthUser.maxPasswordLength), isNull);
      expect(
        issueFor('a' * (AuthUser.maxPasswordLength + 1)),
        const ValidationIssue.tooLong(
          ValidatedInput.password,
          max: AuthUser.maxPasswordLength,
        ),
      );
    });

    test('refuses spaces at the ends, instead of trimming them', () {
      const invalid = ValidationIssue.invalidFormat(ValidatedInput.password);
      expect(issueFor(' hunter22'), invalid);
      expect(issueFor('hunter22 '), invalid);
    });

    test('allows spaces inside, and any alphabet', () {
      expect(issueFor('correct horse battery'), isNull);
      expect(issueFor('пароль-для-покупок'), isNull);
    });

    test('returns the password normalized, so both ways of typing "é" '
        'become the same password', () {
      const composed = 'café-latte'; // é as one character
      const decomposed = 'café-latte'; // e + combining accent
      expect(composed == decomposed, isFalse);

      expect(
        AuthUser.validatePassword(decomposed),
        AuthUser.validatePassword(composed),
      );
      expect(
        AuthUser.normalizePassword(decomposed),
        AuthUser.normalizePassword(composed),
      );
    });
  });
}
