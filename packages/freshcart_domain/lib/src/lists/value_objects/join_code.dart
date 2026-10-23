import 'package:freshcart_domain/src/core/failure.dart';
import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/core/validation_issue.dart';

/// The short code to join someone else's list.
///
/// Five characters, without `I`, `O`, `0` and `1` (they look too alike), so
/// codes are easy to read and type.
extension type const JoinCode._(String value) implements Object {
  /// The characters a code can have.
  static const String alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// How many characters a code has.
  static const int length = 5;

  /// Turns what the user typed into a code (uppercase, no spaces at the
  /// ends).
  ///
  /// Returns a [Result] (doesn't throw), because a wrong code from a text
  /// field is normal, not a bug.
  static Result<JoinCode> parse(String input) {
    final cleaned = input.trim().toUpperCase().replaceAll('-', '');
    if (cleaned.length != length) {
      return const Err(
        Failure.validation(
          ValidationIssue.invalidFormat(ValidatedInput.joinCode),
        ),
      );
    }
    for (final unit in cleaned.split('')) {
      if (!alphabet.contains(unit)) {
        return const Err(
          Failure.validation(
            ValidationIssue.invalidFormat(ValidatedInput.joinCode),
          ),
        );
      }
    }
    return Ok(JoinCode._(cleaned));
  }
}
