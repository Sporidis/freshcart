import 'package:freshcart_domain/src/core/clock.dart';
import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/items/entities/shopping_item.dart';
import 'package:freshcart_domain/src/items/ports/item_repository.dart';
import 'package:freshcart_domain/src/shops/value_objects/shop_id.dart';

/// Applies a user's edit to an existing item, enforcing the same rules the
/// item had to satisfy to be added in the first place.
///
/// Exists because [AddItem] and this use case are two doors into the same
/// fields: a name that is illegal to create must stay illegal to rename to.
/// Before this, the edit path went straight to [ItemRepository.save] and
/// enforced nothing, so an item could be edited into a state it could never
/// have been created in — a blank name, or a quantity of zero.
class EditItem {
  /// Creates the use case against an [ItemRepository] and a [Clock].
  const EditItem(this._items, {this.clock = systemClock});

  final ItemRepository _items;

  /// Supplies the note's `updatedAt`. Override it in tests to pin "now".
  final Clock clock;

  /// Validates the edit and persists it.
  ///
  /// [noteText] is the note's new body: `null` or blank clears the note
  /// entirely, which is why it is not simply forwarded as-is.
  ///
  /// [shopId] is passed through as given, so `null` untags the item — the
  /// "no shop" choice in the editor has to be expressible.
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
