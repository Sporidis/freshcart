import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/lists/value_objects/list_id.dart';
import 'package:freshcart_domain/src/shops/entities/shop.dart';
import 'package:freshcart_domain/src/shops/entities/shop_item_disposition.dart';
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

  /// How many items are tagged to shop [id].
  ///
  /// Asked before offering to delete it, because "delete Colruyt" reads very
  /// differently when it is holding six things than when it is empty.
  Future<Result<int>> itemCount(ShopId id);

  /// Deletes shop [id], disposing of its items as [disposition] says.
  ///
  /// The caller must choose. Items are never destroyed silently — and never
  /// silently kept, either, when someone meant to clear them out.
  /// [ShopItemDisposition.untag] leaves them on the list without a shop, which
  /// is the safe default but is still stated rather than assumed.
  Future<Result<void>> remove(
    ShopId id, {
    ShopItemDisposition disposition,
    ShopId? moveTo,
  });
}
