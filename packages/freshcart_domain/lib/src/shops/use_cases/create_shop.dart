import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/lists/value_objects/list_id.dart';
import 'package:freshcart_domain/src/shops/entities/shop.dart';
import 'package:freshcart_domain/src/shops/ports/shop_repository.dart';
import 'package:freshcart_domain/src/shops/value_objects/hex_color.dart';

/// Adds a shop to a list.
///
/// The colour needs no validation of its own: [HexColor] is already a
/// validated value object, so an unusable colour cannot reach this point.
class CreateShop {
  /// Creates the use case against a [ShopRepository].
  const CreateShop(this._shops);

  final ShopRepository _shops;

  /// Validates [name] and creates the shop on [listId].
  Future<Result<Shop>> call({
    required ListId listId,
    required String name,
    required HexColor color,
  }) async => switch (Shop.validateName(name)) {
    Err(:final failure) => Err(failure),
    Ok(:final value) => await _shops.create(
      listId: listId,
      name: value,
      color: color,
    ),
  };
}
