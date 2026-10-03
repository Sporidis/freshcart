import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/lists/value_objects/list_id.dart';
import 'package:freshcart_domain/src/shops/entities/shop.dart';
import 'package:freshcart_domain/src/shops/entities/shop_item_disposition.dart';
import 'package:freshcart_domain/src/shops/value_objects/hex_color.dart';
import 'package:freshcart_domain/src/shops/value_objects/shop_id.dart';

/// The interface for reading and saving a list's shops.
abstract interface class ShopRepository {
  /// All shops on [listId].
  Future<Result<List<Shop>>> byList(ListId listId);

  /// Creates a shop called [name] with colour [color] on [listId].
  Future<Result<Shop>> create({
    required ListId listId,
    required String name,
    required HexColor color,
  });

  /// Saves the whole [shop].
  Future<Result<Shop>> save(Shop shop);

  /// How many items shop [id] has. Asked before deleting, because deleting
  /// a shop with 6 items is a different decision than an empty one.
  Future<Result<int>> itemCount(ShopId id);

  /// Deletes shop [id]. [disposition] says what happens to its items.
  ///
  /// The caller must always choose, so items are never deleted (or kept)
  /// without the user deciding. [ShopItemDisposition.untag] (keep them
  /// without a shop) is the safe choice.
  Future<Result<void>> remove(
    ShopId id, {
    ShopItemDisposition disposition,
    ShopId? moveTo,
  });
}
