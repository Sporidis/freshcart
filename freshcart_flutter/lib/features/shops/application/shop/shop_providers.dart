import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/shops/application/shop_color_preview/shop_color_preview_controller.dart';
import 'package:freshcart_flutter/features/shops/application/shop_filter/shop_filter_controller.dart';
import 'package:freshcart_flutter/features/shops/application/shops/shops_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shop_providers.g.dart';

/// The colour of the selected shop tab, or null for "All".
///
/// Calculated from the filter (not saved separately), so they always match.
@riverpod
HexColor? activeShopColor(Ref ref, ListId listId) {
  final filter = ref.watch(shopFilterControllerProvider(listId));
  if (filter == null) return null;

  final shops = ref.watch(shopsControllerProvider(listId));
  final loaded = shops.dataOrNull ?? const <Shop>[];
  for (final shop in loaded) {
    // A hidden shop has no tab, so it can't colour the app either.
    if (shop.id == filter && shop.isActive) return shop.color;
  }
  return null;
}

/// The colour to draw [shop] in right now. If the user is trying out a new
/// colour in the edit sheet, that preview colour is returned.
///
/// Everything that draws a shop colour uses this, so the preview shows up
/// everywhere at once.
@riverpod
HexColor effectiveShopColor(Ref ref, Shop shop) {
  final preview = ref.watch(shopColorPreviewControllerProvider);
  if (preview == null || preview.shopId != shop.id) return shop.color;
  return preview.color;
}
