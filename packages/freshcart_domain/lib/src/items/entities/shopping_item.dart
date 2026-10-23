import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshcart_domain/src/auth/value_objects/user_id.dart';
import 'package:freshcart_domain/src/core/failure.dart';
import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/core/validation_issue.dart';
import 'package:freshcart_domain/src/items/entities/note.dart';
import 'package:freshcart_domain/src/items/value_objects/item_id.dart';
import 'package:freshcart_domain/src/lists/value_objects/list_id.dart';
import 'package:freshcart_domain/src/shops/value_objects/shop_id.dart';

part 'shopping_item.freezed.dart';

/// One item on a shopping list.
///
/// [shopId] can be null, because a shop is optional. An item without a
/// shop shows on every shop tab.
///
/// [updatedAt] is used to detect conflicts. When saving, the app sends the
/// [updatedAt] it last saw. If the server's copy is newer (someone else
/// changed it), the server answers `Failure.conflict()` and the app undoes
/// its change.
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
    // Has a default (not required), because most code that makes an item
    // doesn't care about order. The real value only comes from the server
    // (when adding) and from dragging (sortOrderBetween).
    @Default(0) double sortOrder,
    ShopId? shopId,
    Note? note,
    UserId? checkedBy,
    DateTime? checkedAt,

    /// True while this item has a change waiting in the offline queue (not
    /// saved on the server yet). Then `id` may be a temporary id. See
    /// `docs/offline-sync-plan.md` §2.
    @Default(false) bool pending,
  }) = _ShoppingItem;

  const ShoppingItem._();

  /// Maximum name length. Anything longer should be a note.
  static const int maxNameLength = 80;

  /// Checks a name and returns it without spaces at the ends.
  ///
  /// On the entity (not in a use case), because both `AddItem` and
  /// `EditItem` need the same rule. A name you can't create, you also can't
  /// rename to.
  ///
  /// Static, because it's needed before the item exists (when adding).
  static Result<String> validateName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Err(
        Failure.validation(ValidationIssue.missing(ValidatedInput.itemName)),
      );
    }
    if (trimmed.length > maxNameLength) {
      return const Err(
        Failure.validation(
          ValidationIssue.tooLong(ValidatedInput.itemName, max: maxNameLength),
        ),
      );
    }
    return Ok(trimmed);
  }

  /// [text] without spaces at the ends, or null if nothing is left: a
  /// blank note is no note.
  static String? cleanNoteText(String? text) {
    final trimmed = text?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  /// Checks a quantity: at least 1. No maximum, because there's no sensible
  /// limit on how many of something people buy.
  static Result<int> validateQuantity(int quantity) {
    if (quantity < 1) {
      return const Err(
        Failure.validation(
          ValidationIssue.tooFew(ValidatedInput.quantity, min: 1),
        ),
      );
    }
    return Ok(quantity);
  }

  /// Whether a new item ([nameB], [noteTextB]) is the same product as an
  /// existing one ([nameA], [noteTextA]). If so, adding it increases the
  /// existing item's quantity instead of making a new row.
  ///
  /// - Names are compared without spaces at the ends.
  /// - Notes are compared by text only (empty = no note). Not by the whole
  ///   `Note`, because that also has the author and time, which almost never
  ///   match.
  ///
  /// Same shop and checked state are checked by the caller.
  static bool sameProduct({
    required String nameA,
    required String? noteTextA,
    required String nameB,
    required String? noteTextB,
  }) {
    String? normalize(String? text) =>
        (text == null || text.trim().isEmpty) ? null : text.trim();
    return nameA.trim() == nameB.trim() &&
        normalize(noteTextA) == normalize(noteTextB);
  }

  /// The space between new items' [sortOrder] values (0, 1024, 2048...).
  ///
  /// Why a gap and not 1, 2, 3? To move an item between two others,
  /// [sortOrderBetween] just takes the average of their values. No other
  /// rows need to change.
  ///
  /// Each move into the same spot halves the gap. Eventually the numbers get
  /// too close for a `double` to tell apart. That's not handled, but with
  /// 1024 it takes a very large number of moves to the same spot.
  static const double sortOrderGap = 1024;

  /// A [sortOrder] between [before] and [after] (null = start or end of the
  /// list). Used when dragging an item.
  ///
  /// In the domain, so the screen (showing it right away) and the save use
  /// exactly the same number. Otherwise the item would jump when the server
  /// answers.
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

  /// Whether this item shows on shop tab [filter].
  ///
  /// `null` (the "All" tab) shows everything. An item without a shop shows
  /// on every tab, so forgetting to pick a shop never hides it.
  bool matchesShopFilter(ShopId? filter) =>
      filter == null || shopId == null || shopId == filter;

  /// Returns this item checked (if it wasn't) or unchecked (if it was).
  ///
  /// Checking saves who and when; unchecking clears both. On the entity, so
  /// the screen (showing it right away) and the save use the same rule.
  ShoppingItem toggleChecked({required UserId by, required DateTime at}) =>
      isChecked
      ? copyWith(isChecked: false, checkedBy: null, checkedAt: null)
      : copyWith(isChecked: true, checkedBy: by, checkedAt: at);

  /// Returns this item with the user's edit applied.
  ///
  /// On the entity, like [toggleChecked], so the screen and `EditItem` use
  /// exactly the same change.
  ///
  /// [name] and [quantity] must already be checked with [validateName] and
  /// [validateQuantity]. This method doesn't check them.
  ///
  /// An empty or null [noteText] removes the note. The note's author stays
  /// whoever wrote it last (or who added the item). [at] is the note's new
  /// time, until the server sends back the saved item.
  ShoppingItem withEdit({
    required String name,
    required int quantity,
    required DateTime at,
    ShopId? shopId,
    String? noteText,
  }) {
    final text = cleanNoteText(noteText);
    return copyWith(
      name: name,
      quantity: quantity,
      shopId: shopId,
      note: text != null
          ? Note(
              text: text,
              authorId: note?.authorId ?? addedBy,
              updatedAt: at,
            )
          : null,
    );
  }
}
