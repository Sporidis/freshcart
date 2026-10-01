import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/shops/application/shop_color_preview/shop_color_preview_controller.dart';
import 'package:freshcart_flutter/features/shops/application/shop_filter/shop_filter_controller.dart';
import 'package:freshcart_flutter/features/shops/application/shops/shops_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shop_providers.g.dart';

/// The colour of the active shop, or null when no shop is selected.
///
/// Derived rather than stored, so it cannot drift out of step with the filter.
@riverpod
HexColor? activeShopColor(Ref ref, ListId listId) {
  final filter = ref.watch(shopFilterControllerProvider(listId));
  if (filter == null) return null;

  final shops = ref.watch(shopsControllerProvider(listId));
  final loaded = shops.dataOrNull ?? const <Shop>[];
  for (final shop in loaded) {
    // An inactive shop has no tab to have been selected from, so its
    // colour should not be able to leak into the theme either.
    if (shop.id == filter && shop.isActive) return shop.color;
  }
  return null;
}

/// The colour [shop] should be drawn in right now, preview included.
///
/// Every place that paints a shop's colour goes through this, so a preview
/// cannot reach some dots and miss others.
@riverpod
HexColor effectiveShopColor(Ref ref, Shop shop) {
  final preview = ref.watch(shopColorPreviewControllerProvider);
  if (preview == null || preview.shopId != shop.id) return shop.color;
  return preview.color;
}
