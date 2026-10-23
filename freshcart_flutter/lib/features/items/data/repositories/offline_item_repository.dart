import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_entity_type.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_op_type.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_operations_queue.dart';

/// An [ItemRepository] that keeps working offline.
///
/// Wraps another [ItemRepository] (the remote one) and passes every call
/// through. Only when that comes back as [NetworkFailure] (the server
/// couldn't be reached) does it step in: it queues the change for later
/// and answers as if it worked, marked `pending`.
class OfflineItemRepository implements ItemRepository {
  OfflineItemRepository(this._remote, this._queue, this._currentUserId);

  final ItemRepository _remote;
  final PendingOperationsQueue _queue;

  /// The signed-in user's id, read when needed (it can change).
  final UserId Function() _currentUserId;

  // ── Writes: pass through, queue when offline ─────────────────────────

  @override
  Future<Result<ShoppingItem>> add({
    required ListId listId,
    required String name,
    int quantity = 1,
    ShopId? shopId,
    String? noteText,
  }) async {
    final result = await _remote.add(
      listId: listId,
      name: name,
      quantity: quantity,
      shopId: shopId,
      noteText: noteText,
    );
    if (!_isOffline(result)) return result;

    // The queue and the screen share one temporary id, so later offline
    // changes to this item (checking it) point at the right one.
    final tempId = _newTempId();
    await _enqueue(PendingOpType.create, tempId: tempId, {
      'listId': listId.value,
      'name': name,
      'quantity': quantity,
      'shopId': shopId?.value,
      'noteText': noteText,
    });
    return Ok(
      _pendingNewItem(
        ItemId(tempId),
        listId: listId,
        name: name,
        quantity: quantity,
        shopId: shopId,
        noteText: noteText,
      ),
    );
  }

  @override
  Future<Result<ShoppingItem>> save(ShoppingItem item) => _remote.save(item);

  @override
  Future<Result<void>> remove(ItemId id) => _remote.remove(id);

  @override
  Future<Result<int>> clearChecked(ListId listId) =>
      _remote.clearChecked(listId);

  @override
  Future<Result<int>> removeMany(ListId listId, List<ItemId> ids) =>
      _remote.removeMany(listId, ids);

  @override
  Future<Result<int>> moveMany(
    ListId listId,
    List<ItemId> ids,
    ShopId? shopId,
  ) => _remote.moveMany(listId, ids, shopId);

  // ── Reads: pass through ──────────────────────────────────────────────

  @override
  Future<Result<List<ShoppingItem>>> byList(ListId listId) =>
      _remote.byList(listId);

  @override
  Stream<Result<List<ShoppingItem>>> watchByList(ListId listId) =>
      _remote.watchByList(listId);

  @override
  Future<Result<List<String>>> suggestNames(ListId listId, String query) =>
      _remote.suggestNames(listId, query);

  @override
  Future<Result<List<NameHistoryEntry>>> recentNames(ListId listId) =>
      _remote.recentNames(listId);

  // ── Offline helpers ──────────────────────────────────────────────────

  /// Whether [result] failed only because the server couldn't be reached.
  static bool _isOffline(Result<Object?> result) => switch (result) {
    Err(failure: NetworkFailure()) => true,
    _ => false,
  };

  /// Saves an item change to send once the server is reachable again.
  Future<void> _enqueue(
    PendingOpType opType,
    Map<String, Object?> payload, {
    String? tempId,
  }) => _queue.enqueue(
    entityType: PendingEntityType.item,
    opType: opType,
    tempId: tempId,
    payload: payload,
  );

  /// The item to show for an add that's waiting in the queue.
  ShoppingItem _pendingNewItem(
    ItemId id, {
    required ListId listId,
    required String name,
    required int quantity,
    required ShopId? shopId,
    required String? noteText,
  }) {
    final me = _currentUserId();
    final now = DateTime.now().toUtc();
    final note = ShoppingItem.cleanNoteText(noteText);
    return ShoppingItem(
      id: id,
      listId: listId,
      name: name,
      quantity: quantity,
      shopId: shopId,
      note: note == null
          ? null
          : Note(text: note, authorId: me, updatedAt: now),
      addedBy: me,
      createdAt: now,
      updatedAt: now,
      pending: true,
    );
  }

  /// A temporary id for something created offline, until the server gives
  /// it a real one.
  static String _newTempId() => 'temp-${DateTime.now().microsecondsSinceEpoch}';
}
