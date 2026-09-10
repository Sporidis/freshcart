import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/items/entities/shopping_item.dart';
import 'package:freshcart_domain/src/items/ports/item_repository.dart';

/// Moves an item to a new manual position, between two neighbours.
///
/// The position itself is [ShoppingItem.sortOrderBetween] — an invariant of
/// the entity, not a rule this use case owns — so the same arithmetic the
/// server ends up storing is what the presentation layer applies
/// optimistically while the write is in flight.
class ReorderItem {
  /// Creates the use case against an [ItemRepository].
  const ReorderItem(this._items);

  final ItemRepository _items;

  /// Moves [item] to sit between [before] and [after] (either may be null,
  /// for the top or the bottom of the list).
  ///
  /// Returns `Failure.conflict()` if someone else changed the item first; the
  /// caller then rolls its optimistic move back.
  Future<Result<ShoppingItem>> call(
    ShoppingItem item, {
    required ShoppingItem? before,
    required ShoppingItem? after,
  }) => _items.save(
    item.copyWith(sortOrder: ShoppingItem.sortOrderBetween(before, after)),
  );
}
