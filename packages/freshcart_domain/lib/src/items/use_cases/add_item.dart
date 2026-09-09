import 'package:freshcart_domain/src/core/failure.dart';
import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/items/entities/shopping_item.dart';
import 'package:freshcart_domain/src/items/ports/item_repository.dart';
import 'package:freshcart_domain/src/lists/value_objects/list_id.dart';
import 'package:freshcart_domain/src/shops/value_objects/shop_id.dart';

/// Adds an item to a list, enforcing the rules an item must satisfy.
class AddItem {
  /// Creates the use case against an [ItemRepository].
  const AddItem(this._items);

  final ItemRepository _items;

  /// The longest an item name may be.
  ///
  /// A list is read at arm's length in a shop; a name past this is a note.
  static const int maxNameLength = 80;

  /// Validates the input and appends the item to [listId].
  ///
  /// Rejects a blank name and a quantity below one *before* touching the
  /// network — the check belongs to the domain, not to a form widget, so the
  /// rule holds no matter which screen calls it.
  Future<Result<ShoppingItem>> call({
    required ListId listId,
    required String name,
    int quantity = 1,
    ShopId? shopId,
    String? noteText,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return const Err(Failure.validation('name', 'Give the item a name'));
    }
    if (trimmedName.length > maxNameLength) {
      return const Err(
        Failure.validation('name', 'That name is too long for a list'),
      );
    }
    if (quantity < 1) {
      return const Err(Failure.validation('quantity', 'Add at least one'));
    }

    final trimmedNote = noteText?.trim();
    return _items.add(
      listId: listId,
      name: trimmedName,
      quantity: quantity,
      shopId: shopId,
      noteText: (trimmedNote == null || trimmedNote.isEmpty)
          ? null
          : trimmedNote,
    );
  }
}
