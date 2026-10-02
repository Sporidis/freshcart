import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/shops/entities/shop.dart';
import 'package:freshcart_domain/src/shops/ports/shop_repository.dart';
import 'package:freshcart_domain/src/shops/value_objects/hex_color.dart';

/// Changes a shop's name and/or colour.
///
/// Uses the same name rule as [CreateShop] ([Shop.validateName]).
class EditShop {
  /// Creates the use case against a [ShopRepository].
  const EditShop(this._shops);

  final ShopRepository _shops;

  /// Checks the edit and saves [shop].
  ///
  /// Leave out [name] or [color] to keep it as it is (for example, to only
  /// change the colour).
  Future<Result<Shop>> call(Shop shop, {String? name, HexColor? color}) async =>
      switch (Shop.validateName(name ?? shop.name)) {
        Err(:final failure) => Err(failure),
        Ok(:final value) => await _shops.save(
          shop.copyWith(name: value, color: color ?? shop.color),
        ),
      };
}
