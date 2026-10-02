import 'package:freshcart_domain/src/core/clock.dart';
import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/items/entities/shopping_item.dart';
import 'package:freshcart_domain/src/items/ports/item_repository.dart';
import 'package:freshcart_domain/src/shops/value_objects/shop_id.dart';

/// Saves an edit to an item, with the same rules as when adding it.
///
/// So an item can't be edited into something that couldn't be added (like
/// an empty name or quantity 0).
class EditItem {
  /// Creates the use case against an [ItemRepository] and a [Clock].
  const EditItem(this._items, {this.clock = systemClock});

  final ItemRepository _items;

  /// Gives the note's time. Tests pass a fixed clock.
  final Clock clock;

  /// Checks the edit and saves it.
  ///
  /// [noteText]: the new note text. `null` or empty removes the note.
  ///
  /// [shopId]: the new shop. `null` means "no shop".
  Future<Result<ShoppingItem>> call(
    ShoppingItem item, {
    required String name,
    required int quantity,
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
      Ok(:final value) => await _items.save(
        item.withEdit(
          name: value.name,
          quantity: value.quantity,
          shopId: shopId,
          noteText: noteText,
          at: clock(),
        ),
      ),
    };
  }
}
