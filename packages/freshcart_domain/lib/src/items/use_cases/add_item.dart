import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/items/entities/shopping_item.dart';
import 'package:freshcart_domain/src/items/ports/item_repository.dart';
import 'package:freshcart_domain/src/lists/value_objects/list_id.dart';
import 'package:freshcart_domain/src/shops/value_objects/shop_id.dart';

/// Adds an item to a list, after checking the rules.
class AddItem {
  /// Creates the use case against an [ItemRepository].
  const AddItem(this._items);

  final ItemRepository _items;

  /// Checks the input, then adds the item to [listId].
  ///
  /// The rules are on [ShoppingItem] (like [ShoppingItem.validateName]), so
  /// editing uses the same ones. They run before calling the server, and in
  /// the domain (not in a widget), so every screen gets them.
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

    return switch (validated) {
      Err(:final failure) => Err(failure),
      Ok(:final value) => await _items.add(
        listId: listId,
        name: value.name,
        quantity: value.quantity,
        shopId: shopId,
        noteText: ShoppingItem.cleanNoteText(noteText),
      ),
    };
  }
}
