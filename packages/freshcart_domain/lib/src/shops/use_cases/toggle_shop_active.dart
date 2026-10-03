import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/shops/entities/shop.dart';
import 'package:freshcart_domain/src/shops/ports/shop_repository.dart';

/// Shows or hides a shop's tab.
///
/// Like [ToggleItemChecked]: the change itself is [Shop.toggleActive], and
/// this use case only saves it. So the screen can use the same method to
/// show it right away.
class ToggleShopActive {
  /// Creates the use case against a [ShopRepository].
  const ToggleShopActive(this._shops);

  final ShopRepository _shops;

  /// Shows or hides [shop]'s tab, and saves it. Returns `Err` if saving
  /// fails.
  Future<Result<Shop>> call(Shop shop) async =>
      _shops.save(shop.toggleActive());
}
