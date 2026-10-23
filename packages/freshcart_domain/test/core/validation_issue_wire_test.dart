import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

void main() {
  group('ValidationIssueWire', () {
    // One of every case: if a new case is added and not wired, its
    // round trip comes back null and this fails.
    final issues = [
      const ValidationIssue.missing(ValidatedInput.itemName),
      const ValidationIssue.tooLong(ValidatedInput.listName, max: 60),
      const ValidationIssue.tooShort(ValidatedInput.displayName, min: 2),
      const ValidationIssue.tooFew(ValidatedInput.quantity, min: 1),
      const ValidationIssue.tooLarge(
        ValidatedInput.avatarPhoto,
        maxBytes: 5242880,
      ),
      const ValidationIssue.invalidFormat(ValidatedInput.joinCode),
      const ValidationIssue.notFound(ValidatedInput.joinCode),
      const ValidationIssue.alreadyInUse(ValidatedInput.email),
    ];

    for (final issue in issues) {
      test('${issue.kind} survives the round trip', () {
        final back = ValidationIssueWire.fromWire(
          kind: issue.kind,
          input: issue.input.name,
          limit: issue.limit,
        );
        expect(back, issue);
      });
    }

    test('an unknown case or input comes back null, not a crash', () {
      expect(
        ValidationIssueWire.fromWire(kind: 'newerCase', input: 'itemName'),
        isNull,
      );
      expect(
        ValidationIssueWire.fromWire(kind: 'missing', input: 'newerInput'),
        isNull,
      );
    });
  });
}
