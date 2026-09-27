import 'package:freshcart_domain/freshcart_domain.dart';

/// Converts a [ShoppingItem] to and from the JSON shape a queued `edit`
/// stores — the full entity, not just the fields a user edit changed, since
/// replaying it means calling `save()`, which needs a complete item.
///
/// Both directions live here, together, so the writer (`ItemRepositoryImpl
/// .save`'s `onUnreachable`) and the reader (`QueueDrainer`) can never drift
/// out of sync on which keys exist.
extension ShoppingItemQueuePayload on ShoppingItem {
  /// Serializes this item for [PendingOperationsQueue.enqueue].
  Map<String, dynamic> toQueuePayload() => {
    'itemId': id.value,
    'listId': listId.value,
    'name': name,
    'addedBy': addedBy.value,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'quantity': quantity,
    'isChecked': isChecked,
    'sortOrder': sortOrder,
    'shopId': shopId?.value,
    'noteText': note?.text,
    'noteAuthorId': note?.authorId.value,
    'noteUpdatedAt': note?.updatedAt.toIso8601String(),
    'checkedBy': checkedBy?.value,
    'checkedAt': checkedAt?.toIso8601String(),
  };
}

/// Rebuilds the [ShoppingItem] a queued `edit` was captured from —
/// the inverse of [ShoppingItemQueuePayload.toQueuePayload].
ShoppingItem shoppingItemFromQueuePayload(Map<String, dynamic> payload) {
  final noteText = payload['noteText'] as String?;
  return ShoppingItem(
    id: ItemId(payload['itemId'] as String),
    listId: ListId(payload['listId'] as String),
    name: payload['name'] as String,
    addedBy: UserId(payload['addedBy'] as String),
    createdAt: DateTime.parse(payload['createdAt'] as String),
    updatedAt: DateTime.parse(payload['updatedAt'] as String),
    quantity: payload['quantity'] as int,
    isChecked: payload['isChecked'] as bool,
    sortOrder: payload['sortOrder'] as double,
    shopId: payload['shopId'] == null
        ? null
        : ShopId(payload['shopId'] as String),
    note: noteText == null
        ? null
        : Note(
            text: noteText,
            authorId: UserId(payload['noteAuthorId'] as String),
            updatedAt: DateTime.parse(payload['noteUpdatedAt'] as String),
          ),
    checkedBy: payload['checkedBy'] == null
        ? null
        : UserId(payload['checkedBy'] as String),
    checkedAt: payload['checkedAt'] == null
        ? null
        : DateTime.parse(payload['checkedAt'] as String),
  );
}
