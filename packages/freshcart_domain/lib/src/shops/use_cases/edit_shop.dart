import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/shops/entities/shop.dart';
import 'package:freshcart_domain/src/shops/ports/shop_repository.dart';
import 'package:freshcart_domain/src/shops/value_objects/hex_color.dart';

/// Renames a shop and/or changes its colour.
///
/// The counterpart to [CreateShop], sharing its rules through
/// [Shop.validateName]. Recolouring is what makes this more than a rename:
/// a shop's colour seeds the whole app's theme when that shop is active, so
/// the write has to go through the same door as everything else.
class EditShop {
  /// Creates the use case against a [ShopRepository].
  const EditShop(this._shops);

  final ShopRepository _shops;

  /// Validates the edit and writes [shop] back.
  ///
  /// Omitting [name] or [color] leaves that field as it is, so a caller
  /// changing only the colour need not restate the name.
  Future<Result<Shop>> call(Shop shop, {String? name, HexColor? color}) async =>
      switch (Shop.validateName(name ?? shop.name)) {
        Err(:final failure) => Err(failure),
        Ok(:final value) => await _shops.save(
          shop.copyWith(name: value, color: color ?? shop.color),
        ),
      };
}
