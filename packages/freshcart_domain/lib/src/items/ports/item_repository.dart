import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/items/entities/name_history_entry.dart';
import 'package:freshcart_domain/src/items/entities/shopping_item.dart';
import 'package:freshcart_domain/src/items/value_objects/item_id.dart';
import 'package:freshcart_domain/src/lists/value_objects/list_id.dart';
import 'package:freshcart_domain/src/shops/value_objects/shop_id.dart';

/// The interface for reading and saving items. The app implements it with
/// Serverpod.
abstract interface class ItemRepository {
  /// All items on list [listId].
  Future<Result<List<ShoppingItem>>> byList(ListId listId);

  /// Adds a new item to [listId].
  ///
  /// Takes separate fields (not a [ShoppingItem]), because the server
  /// creates the id and dates.
  Future<Result<ShoppingItem>> add({
    required ListId listId,
    required String name,
    int quantity,
    ShopId? shopId,
    String? noteText,
  });

  /// Saves the whole [item].
  ///
  /// One save method for every change (rename, shop, note, check), instead
  /// of one per field. So the server has one place to check `updatedAt` and
  /// answer `Failure.conflict()` if someone else changed it first.
  Future<Result<ShoppingItem>> save(ShoppingItem item);

  /// Deletes item [id].
  Future<Result<void>> remove(ItemId id);

  /// Deletes all checked items on [listId]. Returns how many were deleted.
  Future<Result<int>> clearChecked(ListId listId);

  /// Deletes the items [ids] from [listId] ("Delete" in select mode).
  /// Returns how many were deleted.
  Future<Result<int>> removeMany(ListId listId, List<ItemId> ids);

  /// Moves the items [ids] to shop [shopId] ("Move" in select mode; null =
  /// no shop). Returns how many were moved.
  Future<Result<int>> moveMany(ListId listId, List<ItemId> ids, ShopId? shopId);

  /// The items on [listId], updated live when anyone changes them.
  Stream<Result<List<ShoppingItem>>> watchByList(ListId listId);

  /// Item names used on [listId] before that match [query], newest first.
  /// For the suggestion chips (decisions.md #64). Only from this list.
  Future<Result<List<String>>> suggestNames(ListId listId, String query);

  /// Every item name ever used on [listId], newest first. For "Recently
  /// bought". Like [suggestNames], but without a search text.
  Future<Result<List<NameHistoryEntry>>> recentNames(ListId listId);
}
