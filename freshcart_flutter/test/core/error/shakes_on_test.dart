import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/shakes_on.dart';

void main() {
  group('shakesOn', () {
    test('shakes for what the user can retype', () {
      expect(
        shakesOn(
          const Failure.validation(
            ValidationIssue.invalidFormat(ValidatedInput.joinCode),
          ),
        ),
        isTrue,
      );
      expect(shakesOn(const Failure.notFound()), isTrue);
    });

    // "No shake; it isn't a typo."
    test('does not shake for what is not their mistake', () {
      expect(shakesOn(const Failure.network()), isFalse);
      expect(shakesOn(const Failure.unauthorized()), isFalse);
      expect(shakesOn(const Failure.unexpected()), isFalse);
    });
  });
}
