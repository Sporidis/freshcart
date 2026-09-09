import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/shops/entities/shop.dart';
import 'package:freshcart_domain/src/shops/value_objects/hex_color.dart';
import 'package:freshcart_domain/src/shops/value_objects/shop_id.dart';

/// How the domain reads and writes shops.
abstract interface class ShopRepository {
  /// Every shop available to the signed-in user.
  Future<Result<List<Shop>>> all();

  /// Creates a shop called [name], themed with [color].
  Future<Result<Shop>> create({required String name, required HexColor color});

  /// Writes [shop] back in full.
  Future<Result<Shop>> save(Shop shop);

  /// Deletes shop [id]. Items tagged to it become untagged rather than being
  /// deleted with it.
  Future<Result<void>> remove(ShopId id);
}
