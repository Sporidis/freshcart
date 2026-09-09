import 'package:freshcart_domain/src/core/failure.dart';
import 'package:freshcart_domain/src/core/result.dart';

/// The short code a person types to join someone else's shopping list.
///
/// Six characters from an unambiguous alphabet — no `I`, `O`, `0` or `1` — so a
/// code read aloud in a kitchen or copied off a screen does not turn into a
/// support problem.
extension type const JoinCode._(String value) implements Object {
  /// The characters a generated code may contain.
  static const String alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// How many characters a code has.
  static const int length = 6;

  /// Parses user input, normalising case and surrounding whitespace.
  ///
  /// Returns a [Result] because this is fed straight from a text field, so an
  /// invalid code is an expected outcome rather than a bug.
  static Result<JoinCode> parse(String input) {
    final cleaned = input.trim().toUpperCase().replaceAll('-', '');
    if (cleaned.length != length) {
      return const Err(
        Failure.validation('joinCode', 'A join code is $length characters'),
      );
    }
    for (final unit in cleaned.split('')) {
      if (!alphabet.contains(unit)) {
        return const Err(
          Failure.validation('joinCode', 'That is not a valid join code'),
        );
      }
    }
    return Ok(JoinCode._(cleaned));
  }
}
