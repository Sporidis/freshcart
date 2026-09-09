import 'package:freshcart_domain/src/auth/value_objects/user_id.dart';
import 'package:freshcart_domain/src/core/clock.dart';
import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/items/entities/shopping_item.dart';
import 'package:freshcart_domain/src/items/ports/item_repository.dart';

/// Checks or unchecks an item, recording who did it and when.
///
/// The state change itself is [ShoppingItem.toggleChecked] — an invariant of
/// the entity. This use case only supplies the actor and the clock and persists
/// the result, which is what lets the presentation layer apply the *same*
/// transformation optimistically and stay consistent with what the server will
/// store.
class ToggleItemChecked {
  /// Creates the use case against an [ItemRepository] and a [Clock].
  const ToggleItemChecked(this._items, {this.clock = systemClock});

  final ItemRepository _items;

  /// Supplies the check timestamp. Override it in tests to pin "now".
  final Clock clock;

  /// Flips [item]'s checked state on behalf of [by].
  ///
  /// Returns `Failure.conflict()` if someone else changed the item first; the
  /// caller then rolls its optimistic update back.
  Future<Result<ShoppingItem>> call(
    ShoppingItem item, {
    required UserId by,
  }) => _items.save(item.toggleChecked(by: by, at: clock()));
}
