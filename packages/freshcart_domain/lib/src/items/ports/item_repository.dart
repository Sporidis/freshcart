import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/items/entities/shopping_item.dart';
import 'package:freshcart_domain/src/items/value_objects/item_id.dart';
import 'package:freshcart_domain/src/lists/value_objects/list_id.dart';
import 'package:freshcart_domain/src/shops/value_objects/shop_id.dart';

/// How the domain reads and writes the items on a list.
abstract interface class ItemRepository {
  /// Every item on list [listId].
  Future<Result<List<ShoppingItem>>> byList(ListId listId);

  /// Appends a new item to [listId].
  ///
  /// The server assigns the id and timestamps, which is why this takes loose
  /// arguments rather than a [ShoppingItem] the client would have to fake.
  Future<Result<ShoppingItem>> add({
    required ListId listId,
    required String name,
    int quantity,
    ShopId? shopId,
    String? noteText,
  });

  /// Writes [item] back in full.
  ///
  /// A whole-entity save rather than a set of field-level mutations: it keeps
  /// one write path for every edit (rename, re-tag, note, check) and gives the
  /// server a single place to compare `updatedAt` and answer
  /// `Failure.conflict()` when someone else got there first.
  Future<Result<ShoppingItem>> save(ShoppingItem item);

  /// Deletes item [id].
  Future<Result<void>> remove(ItemId id);

  /// Deletes every checked item on [listId], returning how many were removed.
  Future<Result<int>> clearChecked(ListId listId);

  /// Deletes exactly [ids] from [listId] (a multi-select "Delete"), returning
  /// how many were removed.
  Future<Result<int>> removeMany(ListId listId, List<ItemId> ids);

  /// Reassigns exactly [ids] on [listId] to [shopId] (a multi-select
  /// "Move"; null untags them), returning how many moved.
  Future<Result<int>> moveMany(ListId listId, List<ItemId> ids, ShopId? shopId);

  /// Live view of the items on [listId] (Phase 8).
  Stream<Result<List<ShoppingItem>>> watchByList(ListId listId);

  /// Product names typed on [listId] before, matching [query], most
  /// recently used first -- the add control's suggestion chips (decisions
  /// #64). Scoped to this list only, the same scope shops already use.
  Future<Result<List<String>>> suggestNames(ListId listId, String query);
}
