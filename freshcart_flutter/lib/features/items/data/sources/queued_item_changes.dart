import 'dart:convert';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/offline/database/app_database.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_operations_table.dart';
import 'package:freshcart_flutter/core/offline/queue/shopping_item_queue_payload.dart';

/// Shows [items] (what the server or the offline cache has for [listId])
/// as they will be once the queued offline changes in [ops] are sent.
///
/// Every row a queued change touches comes back with `pending: true`, so
/// the screen can mark it as "not confirmed yet" (offline-sync-plan.md
/// Phase E).
///
/// Why here, from the queue, and not from a flag kept in memory: the
/// queue is saved on the phone and is exactly what's still waiting. So the
/// mark survives the app being closed while offline (the cache only ever
/// holds server data, so without this an offline change wasn't even shown
/// after a restart), and it clears at the moment the change leaves the
/// queue, never earlier or later.
///
/// The changes are replayed in the order they were made, as the drainer
/// will send them. A change for another list, or for a row that isn't
/// here, is skipped.
///
/// [me] gives the signed-in user: everything in this phone's queue was
/// done by them, so they're who added a queued new item. A function, so
/// it's only asked when there is such an item.
List<ShoppingItem> applyQueuedItemChanges(
  List<ShoppingItem> items,
  List<PendingOperation> ops,
  ListId listId, {
  required UserId Function() me,
}) {
  if (ops.isEmpty) return items;
  final rows = [...items];

  int indexOf(String id) => rows.indexWhere((item) => item.id.value == id);

  for (final op in ops) {
    if (op.entityType != PendingEntityType.item) continue;
    final payload = jsonDecode(op.payload) as Map<String, dynamic>;
    final forThisList =
        payload['listId'] == null || payload['listId'] == listId.value;
    if (!forThisList) continue;

    switch (op.opType) {
      case PendingOpType.create:
        final tempId = op.tempId;
        if (tempId == null || indexOf(tempId) >= 0) break;
        rows.add(_createdItem(tempId, payload, listId, me(), op.queuedAt));

      case PendingOpType.edit:
        final at = indexOf(payload['itemId'] as String);
        if (at < 0) break;
        rows[at] = shoppingItemFromQueuePayload(
          payload,
        ).copyWith(pending: true);

      case PendingOpType.remove:
        final at = indexOf(payload['itemId'] as String);
        if (at >= 0) rows.removeAt(at);

      case PendingOpType.removeMany:
        final ids = {...(payload['ids'] as List<dynamic>).cast<String>()};
        rows.removeWhere((item) => ids.contains(item.id.value));

      case PendingOpType.clearChecked:
        rows.removeWhere((item) => item.isChecked);

      case PendingOpType.moveMany:
        final ids = {...(payload['ids'] as List<dynamic>).cast<String>()};
        final shopId = payload['shopId'] as String?;
        for (var i = 0; i < rows.length; i++) {
          if (!ids.contains(rows[i].id.value)) continue;
          rows[i] = rows[i].copyWith(
            shopId: shopId == null ? null : ShopId(shopId),
            pending: true,
          );
        }

      // List changes (rename, delete, ...) don't change the items.
      default:
        break;
    }
  }
  return rows;
}

/// The row for an item added offline, under its temporary id (the one the
/// queue and any later queued edits use).
ShoppingItem _createdItem(
  String tempId,
  Map<String, dynamic> payload,
  ListId listId,
  UserId addedBy,
  DateTime queuedAt,
) {
  final at = queuedAt.toUtc();
  final noteText = payload['noteText'] as String?;
  final shopId = payload['shopId'] as String?;
  return ShoppingItem(
    id: ItemId(tempId),
    listId: listId,
    name: payload['name'] as String,
    addedBy: addedBy,
    createdAt: at,
    updatedAt: at,
    quantity: payload['quantity'] as int? ?? 1,
    shopId: shopId == null ? null : ShopId(shopId),
    note: noteText == null || noteText.trim().isEmpty
        ? null
        : Note(text: noteText, authorId: addedBy, updatedAt: at),
    pending: true,
  );
}
