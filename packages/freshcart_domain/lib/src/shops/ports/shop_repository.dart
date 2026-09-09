import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/lists/value_objects/list_id.dart';
import 'package:freshcart_domain/src/shops/entities/shop.dart';
import 'package:freshcart_domain/src/shops/value_objects/hex_color.dart';
import 'package:freshcart_domain/src/shops/value_objects/shop_id.dart';

/// How the domain reads and writes the shops belonging to a list.
abstract interface class ShopRepository {
  /// Every shop on [listId].
  Future<Result<List<Shop>>> byList(ListId listId);

  /// Creates a shop called [name] on [listId], themed with [color].
  Future<Result<Shop>> create({
    required ListId listId,
    required String name,
    required HexColor color,
  });

  /// Writes [shop] back in full.
  Future<Result<Shop>> save(Shop shop);

  /// Deletes shop [id]. Items tagged to it become untagged rather than being
  /// deleted with it — losing a shop must never lose the shopping.
  Future<Result<void>> remove(ShopId id);
}
