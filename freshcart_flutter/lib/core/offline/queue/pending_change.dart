import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_entity_type.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_op_type.dart';
import 'package:freshcart_flutter/core/offline/queue/shopping_item_queue_payload.dart';

/// One change made offline, waiting in the queue to be sent to the server.
///
/// Each kind of change is its own class, so only the changes that make
/// sense can exist (there is no "rename an item"), and a `switch` over them
/// must handle every one.
sealed class PendingChange {
  const PendingChange();

  /// Rebuilds the change stored in a queue row.
  ///
  /// [tempId] comes from the row's own column, not from [json]: only
  /// creates have one.
  ///
  /// Throws [UnsupportedError] for a combination that can't exist, such as
  /// renaming an item. Such a row is a bug, not a failure to recover from.
  factory PendingChange.fromQueue(
    PendingEntityType entityType,
    PendingOpType opType,
    Map<String, Object?> json, {
    String? tempId,
  }) => switch (entityType) {
    PendingEntityType.item => PendingItemChange.fromQueue(
      opType,
      json,
      tempId: tempId,
    ),
    PendingEntityType.list => PendingListChange.fromQueue(
      opType,
      json,
      tempId: tempId,
    ),
  };

  /// The payload stored in the queue row.
  ///
  /// The keys must never change: rows written by an older version of the
  /// app may still be waiting in the queue.
  Map<String, Object?> toJson();

  /// Whether this changes an item or a list. Stored in the queue row.
  PendingEntityType get entityType;

  /// What kind of change this is. Stored in the queue row.
  PendingOpType get opType;

  /// The temporary id the screen shows until the server gives the real one.
  /// Only creates have one, so it's `null` by default.
  String? get tempId => null;

  /// This change with every temporary id in [realIds] replaced by the
  /// server's real id.
  PendingChange withRealIds(Map<String, String> realIds);
}

// ── Items ──────────────────────────────────────────────────────────────

/// A change to an item.
sealed class PendingItemChange extends PendingChange {
  const PendingItemChange();

  factory PendingItemChange.fromQueue(
    PendingOpType opType,
    Map<String, Object?> json, {
    String? tempId,
  }) => switch (opType) {
    PendingOpType.create => ItemCreated(
      tempId: tempId ?? (throw ArgumentError('An item create needs a tempId')),
      listId: ListId(json['listId'] as String),
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      shopId: json['shopId'] != null ? ShopId(json['shopId'] as String) : null,
      noteText: json['noteText'] as String?,
    ),
    PendingOpType.remove => ItemRemoved(ItemId(json['itemId'] as String)),
    PendingOpType.edit => ItemEdited(shoppingItemFromQueuePayload(json)),
    PendingOpType.clearChecked => CheckedItemsCleared(
      ListId(json['listId'] as String),
    ),
    PendingOpType.removeMany => ItemsRemoved(
      ListId(json['listId'] as String),
      [for (final id in json['ids'] as List<Object?>) ItemId(id as String)],
    ),
    PendingOpType.moveMany => ItemsMovedToShop(
      ListId(json['listId'] as String),
      [for (final id in json['ids'] as List<Object?>) ItemId(id as String)],
      json['shopId'] != null ? ShopId(json['shopId'] as String) : null,
    ),
    _ => throw UnsupportedError(
      'Unsupported operation type: $opType on PendingItemChange',
    ),
  };

  @override
  PendingEntityType get entityType => PendingEntityType.item;
}

/// A new item. [tempId] is the id the screen shows until the server
/// gives the real one.
final class ItemCreated extends PendingItemChange {
  const ItemCreated({
    required this.tempId,
    required this.listId,
    required this.name,
    required this.quantity,
    this.shopId,
    this.noteText,
  });

  @override
  final String tempId;
  final ListId listId;
  final String name;
  final int quantity;
  final ShopId? shopId;
  final String? noteText;

  @override
  Map<String, Object?> toJson() => {
    'listId': listId.value,
    'name': name,
    'quantity': quantity,
    'shopId': shopId?.value,
    'noteText': noteText,
  };

  @override
  PendingOpType get opType => PendingOpType.create;

  @override
  PendingChange withRealIds(Map<String, String> realIds) => ItemCreated(
    tempId: tempId,
    listId: _realListId(listId, realIds),
    name: name,
    quantity: quantity,
    shopId: shopId,
    noteText: noteText,
  );
}

/// An item removed from its list.
final class ItemRemoved extends PendingItemChange {
  const ItemRemoved(this.itemId);

  final ItemId itemId;

  @override
  Map<String, Object?> toJson() => {'itemId': itemId.value};

  @override
  PendingOpType get opType => PendingOpType.remove;

  @override
  PendingChange withRealIds(Map<String, String> realIds) =>
      ItemRemoved(_realItemId(itemId, realIds));
}

/// An item edited.
final class ItemEdited extends PendingItemChange {
  const ItemEdited(this.item);

  final ShoppingItem item;

  @override
  Map<String, Object?> toJson() => item.toQueuePayload();

  @override
  PendingOpType get opType => PendingOpType.edit;

  @override
  PendingChange withRealIds(Map<String, String> realIds) => ItemEdited(
    item.copyWith(
      id: _realItemId(item.id, realIds),
      listId: _realListId(item.listId, realIds),
    ),
  );
}

/// Checked items cleared from a list.
final class CheckedItemsCleared extends PendingItemChange {
  const CheckedItemsCleared(this.listId);

  final ListId listId;

  @override
  Map<String, Object?> toJson() => {'listId': listId.value};

  @override
  PendingOpType get opType => PendingOpType.clearChecked;

  @override
  PendingChange withRealIds(Map<String, String> realIds) =>
      CheckedItemsCleared(_realListId(listId, realIds));
}

/// Several items removed from one list.
final class ItemsRemoved extends PendingItemChange {
  const ItemsRemoved(this.listId, this.itemIds);

  final ListId listId;
  final List<ItemId> itemIds;

  @override
  Map<String, Object?> toJson() => {
    'listId': listId.value,
    'ids': [for (final id in itemIds) id.value],
  };

  @override
  PendingOpType get opType => PendingOpType.removeMany;

  @override
  PendingChange withRealIds(Map<String, String> realIds) => ItemsRemoved(
    _realListId(listId, realIds),
    [for (final id in itemIds) _realItemId(id, realIds)],
  );
}

/// Several items in one list moved to another shop. A `null` [targetShopId]
/// means "no shop".
final class ItemsMovedToShop extends PendingItemChange {
  const ItemsMovedToShop(
    this.listId,
    this.itemIds,
    this.targetShopId,
  );

  final ListId listId;
  final List<ItemId> itemIds;
  final ShopId? targetShopId;

  @override
  Map<String, Object?> toJson() => {
    'listId': listId.value,
    'ids': [for (final id in itemIds) id.value],
    'shopId': targetShopId?.value,
  };

  @override
  PendingOpType get opType => PendingOpType.moveMany;

  // Shops can't be created offline, so targetShopId is never temporary.
  @override
  PendingChange withRealIds(Map<String, String> realIds) => ItemsMovedToShop(
    _realListId(listId, realIds),
    [for (final id in itemIds) _realItemId(id, realIds)],
    targetShopId,
  );
}

// ── Lists ──────────────────────────────────────────────────────────────

/// A change to a list.
sealed class PendingListChange extends PendingChange {
  const PendingListChange();

  factory PendingListChange.fromQueue(
    PendingOpType opType,
    Map<String, Object?> json, {
    String? tempId,
  }) => switch (opType) {
    PendingOpType.create => ListCreated(
      tempId: tempId ?? (throw ArgumentError('A list create needs a tempId')),
      name: json['name'] as String,
    ),
    PendingOpType.rename => ListRenamed(
      ListId(json['id'] as String),
      json['name'] as String,
    ),
    PendingOpType.setClearCheckedAfterShopping => ClearCheckedAfterShoppingSet(
      ListId(json['id'] as String),
      value: json['value'] as bool,
    ),
    PendingOpType.leave => ListLeft(ListId(json['id'] as String)),
    PendingOpType.delete => ListDeleted(ListId(json['id'] as String)),
    PendingOpType.removeMember => MemberRemoved(
      ListId(json['id'] as String),
      UserId(json['userId'] as String),
    ),
    PendingOpType.transferOwnership => OwnershipTransferred(
      ListId(json['id'] as String),
      UserId(json['userId'] as String),
    ),
    _ => throw UnsupportedError(
      'Unsupported operation type: $opType on PendingListChange',
    ),
  };

  @override
  PendingEntityType get entityType => PendingEntityType.list;
}

/// A new list. [tempId] is the id the screen shows until the server
/// gives the real one.
final class ListCreated extends PendingListChange {
  const ListCreated({required this.tempId, required this.name});

  @override
  final String tempId;
  final String name;

  @override
  Map<String, Object?> toJson() => {'name': name};

  @override
  PendingOpType get opType => PendingOpType.create;

  @override
  PendingChange withRealIds(Map<String, String> realIds) => this;
}

/// A list given a new name.
final class ListRenamed extends PendingListChange {
  const ListRenamed(this.listId, this.name);

  final ListId listId;
  final String name;

  @override
  Map<String, Object?> toJson() => {
    'id': listId.value,
    'name': name,
  };

  @override
  PendingOpType get opType => PendingOpType.rename;

  @override
  PendingChange withRealIds(Map<String, String> realIds) =>
      ListRenamed(_realListId(listId, realIds), name);
}

/// The list's "clear checked items after shopping" setting changed.
final class ClearCheckedAfterShoppingSet extends PendingListChange {
  const ClearCheckedAfterShoppingSet(this.listId, {required this.value});

  final ListId listId;
  final bool value;

  @override
  Map<String, Object?> toJson() => {
    'id': listId.value,
    'value': value,
  };

  @override
  PendingOpType get opType => PendingOpType.setClearCheckedAfterShopping;

  @override
  PendingChange withRealIds(Map<String, String> realIds) =>
      ClearCheckedAfterShoppingSet(_realListId(listId, realIds), value: value);
}

/// The user left a list.
final class ListLeft extends PendingListChange {
  const ListLeft(this.listId);

  final ListId listId;

  @override
  Map<String, Object?> toJson() => {'id': listId.value};

  @override
  PendingOpType get opType => PendingOpType.leave;

  @override
  PendingChange withRealIds(Map<String, String> realIds) =>
      ListLeft(_realListId(listId, realIds));
}

/// The owner deleted a list.
final class ListDeleted extends PendingListChange {
  const ListDeleted(this.listId);

  final ListId listId;

  @override
  Map<String, Object?> toJson() => {'id': listId.value};

  @override
  PendingOpType get opType => PendingOpType.delete;

  @override
  PendingChange withRealIds(Map<String, String> realIds) =>
      ListDeleted(_realListId(listId, realIds));
}

/// The owner removed a member from a list.
final class MemberRemoved extends PendingListChange {
  const MemberRemoved(this.listId, this.userId);

  final ListId listId;
  final UserId userId;

  @override
  Map<String, Object?> toJson() => {
    'id': listId.value,
    'userId': userId.value,
  };

  @override
  PendingOpType get opType => PendingOpType.removeMember;

  // Users can't be created offline, so userId is never temporary.
  @override
  PendingChange withRealIds(Map<String, String> realIds) =>
      MemberRemoved(_realListId(listId, realIds), userId);
}

/// The owner handed the list to another member.
final class OwnershipTransferred extends PendingListChange {
  const OwnershipTransferred(this.listId, this.userId);

  final ListId listId;
  final UserId userId;

  @override
  Map<String, Object?> toJson() => {
    'id': listId.value,
    'userId': userId.value,
  };

  @override
  PendingOpType get opType => PendingOpType.transferOwnership;

  // Users can't be created offline, so userId is never temporary.
  @override
  PendingChange withRealIds(Map<String, String> realIds) =>
      OwnershipTransferred(_realListId(listId, realIds), userId);
}

// ── Helpers ────────────────────────────────────────────────────────────

/// The server's id for [id], or [id] itself if it was never temporary.
ItemId _realItemId(ItemId id, Map<String, String> realIds) =>
    ItemId(realIds[id.value] ?? id.value);

/// The server's id for [id], or [id] itself if it was never temporary.
ListId _realListId(ListId id, Map<String, String> realIds) =>
    ListId(realIds[id.value] ?? id.value);
