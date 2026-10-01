import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shop_color_preview_controller.g.dart';

/// A shop colour being tried out, before anyone commits to it.
///
/// The design's best moment: picking a swatch retints the tab pill and every
/// dot for that shop *behind* the open sheet, so the consequence is visible
/// before it is chosen. That only works if widgets which are not descendants
/// of the sheet can see the pending value — which is precisely why this is
/// app state and not something held inside the sheet's own State.
///
/// Cleared when the sheet closes, whether it saved or not: an abandoned
/// preview must not outlive the sheet that was showing it.
@riverpod
class ShopColorPreviewController extends _$ShopColorPreviewController {
  @override
  ({ShopId shopId, HexColor color})? build() => null;

  /// Tries [color] on [shopId].
  void preview(ShopId shopId, HexColor color) =>
      state = (shopId: shopId, color: color);

  /// Drops the preview, restoring every dot to what is actually stored.
  void clear() => state = null;
}
