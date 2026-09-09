import 'package:freshcart_domain/src/core/failure.dart';
import 'package:freshcart_domain/src/core/result.dart';

/// A shop's seed colour, stored as a 32-bit ARGB integer.
///
/// This is the seed the app feeds to `ColorScheme.fromSeed`, so the whole
/// Material theme shifts to the active shop's colour. The domain stores a plain
/// `int` rather than a Flutter `Color` — that is the entire point of the
/// dependency rule.
extension type const HexColor._(int argb) implements Object {
  /// Wraps a 32-bit ARGB [argb] value.
  ///
  /// Throws [ArgumentError] if it does not fit in 32 bits, which would mean a
  /// caller constructed it wrongly rather than a user typing something odd.
  factory HexColor.fromArgb(int argb) {
    if (argb < 0 || argb > 0xFFFFFFFF) {
      throw ArgumentError.value(argb, 'argb', 'Must be a 32-bit ARGB value');
    }
    return HexColor._(argb);
  }

  /// Parses user input like `#4CAF50`, `4CAF50`, or `#FF4CAF50`.
  ///
  /// Returns a [Result] rather than throwing: this one *is* reachable from user
  /// input (a colour picker's hex field), so it is an expected failure.
  /// A 6-digit value is treated as fully opaque.
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

  /// Renders as `#RRGGBB`, dropping a fully opaque alpha channel.
  String toHex() {
    final rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    if (alpha == 0xFF) return '#${rgb.toUpperCase()}';
    final a = alpha.toRadixString(16).padLeft(2, '0');
    return '#${a.toUpperCase()}${rgb.toUpperCase()}';
  }
}
