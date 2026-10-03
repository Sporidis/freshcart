import 'dart:math' as math;

import 'package:freshcart_domain/src/core/failure.dart';
import 'package:freshcart_domain/src/core/result.dart';

/// A colour (for shops and avatars), stored as a 32-bit ARGB number.
///
/// A plain `int`, not a Flutter `Color`, because the domain can't use
/// Flutter. The app converts it with `HexColorX.toColor()`.
extension type const HexColor._(int argb) implements Object {
  /// Wraps a 32-bit ARGB [argb] value.
  ///
  /// Throws [ArgumentError] if it doesn't fit in 32 bits. That would be a
  /// bug in the code, not a user mistake.
  factory HexColor.fromArgb(int argb) {
    if (argb < 0 || argb > 0xFFFFFFFF) {
      throw ArgumentError.value(argb, 'argb', 'Must be a 32-bit ARGB value');
    }
    return HexColor._(argb);
  }

  /// Reads text like `#4CAF50`, `4CAF50` or `#FF4CAF50`.
  ///
  /// Returns a [Result] (doesn't throw), because this comes from user input,
  /// so a wrong value is normal. 6 digits means fully opaque.
  static Result<HexColor> parse(String input) {
    final cleaned = input.trim().replaceFirst('#', '').toUpperCase();
    if (!RegExp(r'^[0-9A-F]{6}$|^[0-9A-F]{8}$').hasMatch(cleaned)) {
      return const Err(
        Failure.validation('color', 'Expected a hex colour like #4CAF50'),
      );
    }
    final withAlpha = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    return Ok(HexColor._(int.parse(withAlpha, radix: 16)));
  }

  /// The alpha channel, 0-255.
  int get alpha => (argb >> 24) & 0xFF;

  /// The red channel, 0-255.
  int get red => (argb >> 16) & 0xFF;

  /// The green channel, 0-255.
  int get green => (argb >> 8) & 0xFF;

  /// The blue channel, 0-255.
  int get blue => argb & 0xFF;

  /// How different this colour looks from [other] to a human.
  ///
  /// Simple RGB distance doesn't match what eyes see (two blues can look
  /// the same but score far apart). This uses the "redmean" formula: a
  /// simple approximation that's good enough here, without a colour
  /// science library.
  ///
  /// Ignores transparency (shop colours are always opaque).
  ///
  /// From 0 (the same) to about 765 (black vs white).
  double perceptualDistanceTo(HexColor other) {
    final meanRed = (red + other.red) / 2;
    final deltaRed = red - other.red;
    final deltaGreen = green - other.green;
    final deltaBlue = blue - other.blue;
    return math.sqrt(
      (2 + meanRed / 256) * deltaRed * deltaRed +
          4 * deltaGreen * deltaGreen +
          (2 + (255 - meanRed) / 256) * deltaBlue * deltaBlue,
    );
  }

  /// Below this distance, two shop colours are too easy to mix up.
  ///
  /// Set for small 8 px dots seen quickly in a shop. On the safe side: a
  /// warning too many is harmless (the app only warns, never blocks), but a
  /// missed warning could mean buying at the wrong shop.
  static const double confusableDistance = 60;

  /// Whether [other] is close enough to be mistaken for this colour.
  bool isCloseTo(HexColor other) =>
      perceptualDistanceTo(other) < confusableDistance;

  /// As text: `#RRGGBB` (alpha left out when fully opaque).
  String toHex() {
    final rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    if (alpha == 0xFF) return '#${rgb.toUpperCase()}';
    final a = alpha.toRadixString(16).padLeft(2, '0');
    return '#${a.toUpperCase()}${rgb.toUpperCase()}';
  }
}
