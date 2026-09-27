import 'dart:ui';

import 'package:freshcart_domain/freshcart_domain.dart';

/// The one place a domain [HexColor] becomes a Flutter [Color].
///
/// The domain stays Flutter-free (golden rule 1), so the conversion lives
/// here, at the presentation edge -- named like the data layer's own
/// `toDomain()` / `toDto()` mappers, because it is one.
extension HexColorX on HexColor {
  Color toColor() => Color(argb);
}
