import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/error_tier.dart';

void main() {
  group('tierFor', () {
    test('a validation failure is inline wherever it came from', () {
      const failure = Failure.validation(
        ValidationIssue.missing(ValidatedInput.listName),
      );
      for (final source in FailureSource.values) {
        expect(tierFor(failure, source), ErrorTier.inline, reason: '$source');
      }
    });

    // The case that motivates FailureSource existing at all.
    test('the same failure is inline from input and a screen from a load', () {
      const notFound = Failure.notFound();

      expect(tierFor(notFound, FailureSource.input), ErrorTier.inline);
      expect(tierFor(notFound, FailureSource.load), ErrorTier.screen);
    });

    test('a failed write leaves the screen standing, so it is a snackbar', () {
      for (final failure in const [
        Failure.conflict(),
        Failure.network(),
        Failure.unauthorized(),
        Failure.unexpected(),
      ]) {
        expect(
          tierFor(failure, FailureSource.write),
          ErrorTier.snackbar,
          reason: '$failure',
        );
      }
    });

    test('a failed load has nothing left to render, so it is a screen', () {
      for (final failure in const [
        Failure.notFound(),
        Failure.unauthorized(),
        Failure.network(),
        Failure.unexpected(),
      ]) {
        expect(
          tierFor(failure, FailureSource.load),
          ErrorTier.screen,
          reason: '$failure',
        );
      }
    });
  });

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
