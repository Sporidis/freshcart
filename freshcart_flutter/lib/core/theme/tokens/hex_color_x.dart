import 'dart:ui';

import 'package:freshcart_domain/freshcart_domain.dart';

/// Turns a domain [HexColor] into a Flutter [Color].
///
/// The domain package can't import Flutter, so it can't know about [Color].
/// That's why the conversion lives here, in the app.
extension HexColorX on HexColor {
  Color toColor() => Color(argb);
}
