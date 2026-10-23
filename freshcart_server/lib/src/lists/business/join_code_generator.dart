import 'dart:math';

import 'package:freshcart_domain/freshcart_domain.dart';

/// Makes the short codes people type to join a list.
///
/// Uses the characters from the domain's [JoinCode] (not a copy), so the
/// server and the app always agree on which characters are allowed.
abstract final class JoinCodeGenerator {
  static final Random _random = Random.secure();

  /// Makes a random code of [JoinCode.length] characters.
  ///
  /// Uses [Random.secure], because a guessable code would let strangers
  /// join someone's list.
  static String generate() {
    final buffer = StringBuffer();
    for (var i = 0; i < JoinCode.length; i++) {
      buffer.write(
        JoinCode.alphabet[_random.nextInt(JoinCode.alphabet.length)],
      );
    }
    return buffer.toString();
  }
}
