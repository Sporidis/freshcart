import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shop_color_preview_controller.g.dart';

/// A shop colour the user is trying out, before saving it.
///
/// When the user taps a colour in the edit sheet, the shop's tab and dots
/// behind the sheet change colour right away, so they can see how it looks.
/// Those widgets aren't inside the sheet, so the preview has to live in a
/// provider, not in the sheet's own State.
///
/// Cleared when the sheet closes, saved or not.
@riverpod
class ShopColorPreviewController extends _$ShopColorPreviewController {
  @override
  ({ShopId shopId, HexColor color})? build() => null;

  /// Tries [color] on [shopId].
  void preview(ShopId shopId, HexColor color) =>
      state = (shopId: shopId, color: color);

  /// Removes the preview, so the saved colour shows again.
  void clear() => state = null;
}
