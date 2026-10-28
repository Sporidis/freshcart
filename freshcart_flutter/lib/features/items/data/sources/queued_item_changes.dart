import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/offline/database/app_database.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_change.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_operations_queue.dart';

/// Applies the queued offline changes in [ops] to [items], so the list
/// shows what it will look like once they're sent.
///
/// Every row a change touches gets `pending: true`, so the screen can show
/// it as "not confirmed yet".
///
/// We read this from the saved queue, not from memory, so the mark
/// survives an app restart and disappears exactly when the change is sent.
///
/// Changes are applied in the order they were made. Changes for another
/// list, or for a row that isn't in [items], are skipped.
///
/// [me] returns the signed-in user, who made every queued change. It's
/// only called when a queued change adds a new item.
List<ShoppingItem> applyQueuedItemChanges(
  List<ShoppingItem> items,
  List<PendingOperation> ops,
  ListId listId, {
  required UserId Function() me,
}) {
  if (ops.isEmpty) return items;
  final rows = [...items];

  int indexOf(ItemId id) => rows.indexWhere((item) => item.id == id);

  for (final op in ops) {
    final PendingChange change;
    try {
      change = op.toChange();
    } on FormatException {
      continue; // The replayer drops this row; nothing to show for it.
    }
    // List changes (rename, delete, ...) don't change the items.
    if (change is! PendingItemChange) continue;

    // null: the change doesn't say which list (a remove only has the item's
    // id), so it's applied whichever list is open.
    final ListId? changeListId = switch (change) {
      ItemCreated(:final listId) => listId,
      ItemEdited(:final item) => item.listId,
      ItemRemoved() => null,
      CheckedItemsCleared(:final listId) => listId,
      ItemsRemoved(:final listId) => listId,
      ItemsMovedToShop(:final listId) => listId,
    };
    if (changeListId != null && changeListId != listId) continue;

    switch (change) {
      case ItemCreated(:final tempId):
        if (indexOf(ItemId(tempId)) >= 0) break;
        rows.add(_createdItem(change, me(), op.queuedAt));

      case ItemsRemoved(:final itemIds):
        final ids = itemIds.toSet();
        rows.removeWhere((item) => ids.contains(item.id));

      case ItemRemoved(:final itemId):
        rows.removeWhere((item) => item.id == itemId);
      case ItemEdited(:final item):
        final at = indexOf(item.id);
        if (at >= 0) rows[at] = item.copyWith(pending: true);

      case CheckedItemsCleared():
        rows.removeWhere((item) => item.isChecked);

      case ItemsMovedToShop(:final itemIds, :final targetShopId):
        final movedToShopItemIds = itemIds.toSet();
        for (var i = 0; i < rows.length; i++) {
          if (movedToShopItemIds.contains(rows[i].id)) {
            rows[i] = rows[i].copyWith(shopId: targetShopId, pending: true);
          }
        }
    }
  }
  return rows;
}

/// The row for an item added offline, under its temporary id (the one the
/// queue and any later queued edits use).
ShoppingItem _createdItem(
  ItemCreated change,
  UserId addedBy,
  DateTime queuedAt,
) {
  final at = queuedAt.toUtc();
  final noteText = change.noteText;
  return ShoppingItem(
    id: ItemId(change.tempId),
    listId: change.listId,
    name: change.name,
    addedBy: addedBy,
    createdAt: at,
    updatedAt: at,
    quantity: change.quantity,
    shopId: change.shopId,
    note: noteText == null || noteText.trim().isEmpty
        ? null
        : Note(text: noteText, authorId: addedBy, updatedAt: at),
    pending: true,
  );
}
