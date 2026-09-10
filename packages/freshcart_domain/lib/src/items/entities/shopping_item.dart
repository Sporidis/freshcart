import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshcart_domain/src/auth/value_objects/user_id.dart';
import 'package:freshcart_domain/src/core/failure.dart';
import 'package:freshcart_domain/src/core/result.dart';
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
    // A plain default rather than required: almost every call site that
    // builds a ShoppingItem (every test fixture, every mapper round-trip)
    // has no opinion about ordering, and forcing one everywhere sortOrder's
    // real value comes from exactly two places -- ItemService.add, which
    // appends past the current end, and a drag, which computes a midpoint
    // (sortOrderBetween) -- would just be noise at every other call site.
    @Default(0) double sortOrder,
    ShopId? shopId,
    Note? note,
    UserId? checkedBy,
    DateTime? checkedAt,
  }) = _ShoppingItem;

  const ShoppingItem._();

  /// The longest an item name may be.
  ///
  /// A list is read at arm's length in a shop; a name past this is a note.
  static const int maxNameLength = 80;

  /// Validates a proposed item name, returning it trimmed.
  ///
  /// Lives on the entity, not on a use case, for the same reason
  /// [toggleChecked] does: it is an invariant of an item rather than of one
  /// operation on it. `AddItem` and `EditItem` are two doors into the same
  /// field, and a name that is illegal to create must stay illegal to rename
  /// to — one rule, enforced identically at both.
  ///
  /// Static because the check has to hold *before* an item exists: on the add
  /// path the server has not minted the entity yet.
  static Result<String> validateName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Err(Failure.validation('name', 'Give the item a name'));
    }
    if (trimmed.length > maxNameLength) {
      return const Err(
        Failure.validation('name', 'That name is too long for a list'),
      );
    }
    return Ok(trimmed);
  }

  /// Validates a proposed quantity.
  ///
  /// Only a lower bound: there is no sensible ceiling on how many of something
  /// a household might buy, and inventing one would reject a legitimate list.
  static Result<int> validateQuantity(int quantity) {
    if (quantity < 1) {
      return const Err(Failure.validation('quantity', 'Add at least one'));
    }
    return Ok(quantity);
  }

  /// How far apart freshly-appended items are spaced in [sortOrder].
  ///
  /// A gap, not consecutive integers, is what makes [sortOrderBetween] work:
  /// slotting an item between two neighbours only ever needs their average,
  /// never a rewrite of every other row's position. 1024 leaves ten
  /// halvings' worth of room (roughly a thousand manual reorders into the
  /// same gap) before two neighbours' values are close enough that double
  /// precision stops telling them apart -- rebalancing the rest of the list
  /// at that point is a real scenario this does not handle, but a large gap
  /// is what buys the room to not need to.
  static const double sortOrderGap = 1024;

  /// A [sortOrder] placing an item strictly between [before] and [after] --
  /// either may be null for an end of the list -- for a manual drag-reorder.
  ///
  /// Static, and pure arithmetic, for the same reason [toggleChecked] is a
  /// method rather than free-floating logic: the optimistic local move and
  /// the write that follows it must compute the identical value, or the
  /// screen would visibly jump once the server's answer landed.
  static double sortOrderBetween(ShoppingItem? before, ShoppingItem? after) {
    final b = before?.sortOrder;
    final a = after?.sortOrder;
    if (b == null && a == null) return 0;
    if (b == null) return a! - sortOrderGap;
    if (a == null) return b + sortOrderGap;
    return (a + b) / 2;
  }

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

  /// Returns this item with a user's edit applied.
  ///
  /// Public, and on the entity, for the same reason [toggleChecked] is: the
  /// controller applies it optimistically the moment the user hits Save while
  /// `EditItem` applies it on the way to the server, and the two must not be
  /// allowed to drift. One transformation, computed one way.
  ///
  /// Expects [name] and [quantity] to have passed [validateName] and
  /// [validateQuantity] already — this is the shape change, not the guard.
  ///
  /// A blank or absent [noteText] clears the note. The note's author is
  /// whoever last wrote it, falling back to whoever added the item; [at]
  /// stamps it, and stays local until the server echoes the stored row back.
  ShoppingItem withEdit({
    required String name,
    required int quantity,
    required DateTime at,
    ShopId? shopId,
    String? noteText,
  }) {
    final trimmedNote = noteText?.trim();
    final hasNote = trimmedNote != null && trimmedNote.isNotEmpty;
    return copyWith(
      name: name,
      quantity: quantity,
      shopId: shopId,
      note: hasNote
          ? Note(
              text: trimmedNote,
              authorId: note?.authorId ?? addedBy,
              updatedAt: at,
            )
          : null,
    );
  }
}
