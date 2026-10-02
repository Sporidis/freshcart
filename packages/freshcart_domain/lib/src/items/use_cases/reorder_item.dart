import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/items/entities/shopping_item.dart';
import 'package:freshcart_domain/src/items/ports/item_repository.dart';

/// Moves an item to a new position, between two other items.
///
/// The position is calculated by [ShoppingItem.sortOrderBetween], so the
/// screen and the server get the same number.
class ReorderItem {
  /// Creates the use case against an [ItemRepository].
  const ReorderItem(this._items);

  final ItemRepository _items;

  /// Moves [item] to sit between [before] and [after] (either may be null,
  /// for the top or the bottom of the list).
  ///
  /// Returns `Failure.conflict()` if someone else changed the item first.
  /// The caller then undoes the move on screen.
  Future<Result<ShoppingItem>> call(
    ShoppingItem item, {
    required ShoppingItem? before,
    required ShoppingItem? after,
  }) => _items.save(
    item.copyWith(sortOrder: ShoppingItem.sortOrderBetween(before, after)),
  );
}
