import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/shops/entities/shop.dart';
import 'package:freshcart_domain/src/shops/ports/shop_repository.dart';

/// Flips whether [shop] shows as a tab in the shop nav.
///
/// The counterpart to [ToggleItemChecked] for shops: the state change itself
/// is [Shop.toggleActive] -- an invariant of the entity -- and this use case
/// only persists the result, so the presentation layer can apply the same
/// transformation optimistically and stay consistent with what the server
/// stores.
class ToggleShopActive {
  /// Creates a use case that persists a shop's active-state toggle.
  const ToggleShopActive(this._shops);

  final ShopRepository _shops;

  /// Toggles [shop]'s active state and persists the updated shop.
  ///
  /// Returns `Err` when the save fails
  Future<Result<Shop>> call(Shop shop) async =>
      _shops.save(shop.toggleActive());
}
