import 'package:freshcart_domain/src/auth/value_objects/user_id.dart';
import 'package:freshcart_domain/src/core/clock.dart';
import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/items/entities/shopping_item.dart';
import 'package:freshcart_domain/src/items/ports/item_repository.dart';

/// Checks or unchecks an item, and saves who did it and when.
///
/// The change itself is [ShoppingItem.toggleChecked]. This use case only
/// adds the user and the time, and saves it. So the screen can use the
/// same method to show it right away.
class ToggleItemChecked {
  /// Creates the use case against an [ItemRepository] and a [Clock].
  const ToggleItemChecked(this._items, {this.clock = systemClock});

  final ItemRepository _items;

  /// Gives the check time. Tests pass a fixed clock.
  final Clock clock;

  /// Checks or unchecks [item], done by user [by].
  ///
  /// Returns `Failure.conflict()` if someone else changed the item first.
  /// The caller then undoes it on screen.
  Future<Result<ShoppingItem>> call(
    ShoppingItem item, {
    required UserId by,
  }) => _items.save(item.toggleChecked(by: by, at: clock()));
}
