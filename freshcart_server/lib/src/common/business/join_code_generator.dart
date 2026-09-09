import 'dart:math';

import 'package:freshcart_domain/freshcart_domain.dart';

/// Generates the short codes people type to join a list.
///
/// The alphabet comes from the domain's [JoinCode] rather than being repeated
/// here, so the characters the server can emit and the characters the app will
/// accept cannot drift apart.
abstract final class JoinCodeGenerator {
  static final Random _random = Random.secure();

  /// Produces a random code of [JoinCode.length] characters.
  ///
  /// Uses [Random.secure] because a guessable code is a way into someone
  /// else's shopping list.
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
