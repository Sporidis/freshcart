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

  /// Validates the input and appends the item to [listId].
  ///
  /// The rules themselves live on [ShoppingItem] so that editing an item
  /// enforces exactly the same ones — see [ShoppingItem.validateName]. They
  /// run *before* touching the network: the check belongs to the domain, not
  /// to a form widget, so it holds no matter which screen calls it.
  Future<Result<ShoppingItem>> call({
    required ListId listId,
    required String name,
    int quantity = 1,
    ShopId? shopId,
    String? noteText,
  }) async {
    final validated = ShoppingItem.validateName(name).flatMap(
      (validName) => ShoppingItem.validateQuantity(
        quantity,
      ).map((validQuantity) => (name: validName, quantity: validQuantity)),
    );

    final trimmedNote = noteText?.trim();
    return switch (validated) {
      Err(:final failure) => Err(failure),
      Ok(:final value) => await _items.add(
        listId: listId,
        name: value.name,
        quantity: value.quantity,
        shopId: shopId,
        noteText: (trimmedNote == null || trimmedNote.isEmpty)
            ? null
            : trimmedNote,
      ),
    };
  }
}
