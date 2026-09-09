import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshcart_domain/src/auth/value_objects/user_id.dart';
import 'package:freshcart_domain/src/items/entities/note.dart';
import 'package:freshcart_domain/src/items/value_objects/item_id.dart';
import 'package:freshcart_domain/src/lists/value_objects/list_id.dart';
import 'package:freshcart_domain/src/shops/value_objects/shop_id.dart';

part 'shopping_item.freezed.dart';

/// A single line on a shopping list.
///
/// [shopId] is nullable because tagging an item to a shop is optional — an
/// untagged item shows under every shop filter.
///
/// [updatedAt] carries the optimistic-concurrency token. A write sends the
/// value the client last saw; if the stored row has moved on, the server
/// answers `Failure.conflict()` and the client rolls its local edit back.
@freezed
abstract class ShoppingItem with _$ShoppingItem {
  /// Creates a shopping item.
  const factory ShoppingItem({
    required ItemId id,
    required ListId listId,
    required String name,
    required UserId addedBy,
    required DateTime createdAt,
    required DateTime updatedAt,
    @Default(1) int quantity,
    @Default(false) bool isChecked,
    ShopId? shopId,
    Note? note,
    UserId? checkedBy,
    DateTime? checkedAt,
  }) = _ShoppingItem;

  const ShoppingItem._();

  /// Whether this item is tagged to a specific shop.
  bool get hasShop => shopId != null;

  /// Whether this item carries a non-empty note.
  bool get hasNote => note != null && !note!.isEmpty;

  /// Whether this item should appear under the given shop filter.
  ///
  /// A `null` [filter] means "no filter" and matches everything; an untagged
  /// item matches every filter, so a forgotten tag never hides an item.
  bool matchesShopFilter(ShopId? filter) =>
      filter == null || shopId == null || shopId == filter;

  /// Returns this item with its checked state flipped.
  ///
  /// Lives on the entity rather than in the use case because it is a pure
  /// invariant of an item — checking records *who* and *when*, unchecking
  /// clears both — and both the optimistic local update and the reconciliation
  /// path need exactly the same rule.
  ShoppingItem toggleChecked({required UserId by, required DateTime at}) =>
      isChecked
      ? copyWith(isChecked: false, checkedBy: null, checkedAt: null)
      : copyWith(isChecked: true, checkedBy: by, checkedAt: at);
}
