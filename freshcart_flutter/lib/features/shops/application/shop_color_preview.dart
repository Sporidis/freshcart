import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shop_color_preview.g.dart';

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
class ShopColorPreview extends _$ShopColorPreview {
  @override
  ({ShopId shopId, HexColor color})? build() => null;

  /// Tries [color] on [shopId].
  void preview(ShopId shopId, HexColor color) =>
      state = (shopId: shopId, color: color);

  /// Drops the preview, restoring every dot to what is actually stored.
  void clear() => state = null;
}

/// The colour [shop] should be drawn in right now, preview included.
///
/// Every place that paints a shop's colour goes through this, so a preview
/// cannot reach some dots and miss others.
@riverpod
HexColor effectiveShopColor(Ref ref, Shop shop) {
  final preview = ref.watch(shopColorPreviewProvider);
  if (preview == null || preview.shopId != shop.id) return shop.color;
  return preview.color;
}
