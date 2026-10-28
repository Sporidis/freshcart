import 'package:flutter/foundation.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/offline/database/app_database.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_change.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_operations_queue.dart';

/// What happened when we tried to send one queued change.
enum _ReplayOutcome {
  /// The server accepted it. Remove it from the queue.
  succeeded,

  /// Someone else changed the same thing first. The server's version wins,
  /// so we drop our change (and report it).
  conflicted,

  /// Failed for another reason. Keep it and try again next time.
  retryLater,
}

/// Turns a repository [Result] into a [_ReplayOutcome].
_ReplayOutcome _outcomeOf(Result<Object?> result) => switch (result) {
  Ok() => _ReplayOutcome.succeeded,
  Err(failure: ConflictFailure()) => _ReplayOutcome.conflicted,
  Err() => _ReplayOutcome.retryLater,
};

/// Sends the changes made offline to the server, once we're back online.
class PendingOperationsReplayer {
  const PendingOperationsReplayer(
    this._queue,
    this._itemRepository,
    this._listRepository,
  );

  final PendingOperationsQueue _queue;
  final ItemRepository _itemRepository;
  final ListRepository _listRepository;

  /// Sends every queued change, oldest first.
  ///
  /// Returns the changes that were dropped because of a conflict, so the
  /// app can tell the user. Changes that failed for other reasons stay in
  /// the queue. A row that can't be read back is dropped, so it can't
  /// block the changes queued after it.
  Future<List<PendingOperation>> replayAll() async {
    final ops = await _queue.getAll();
    // Temporary id -> real id from the server, filled in as "create"
    // operations succeed. Later changes to the same item or list use it.
    final tempIdToReal = <String, String>{};
    final conflicted = <PendingOperation>[];

    for (final op in ops) {
      final PendingChange change;
      try {
        change = op.toChange().withRealIds(tempIdToReal);
      } on FormatException catch (e) {
        debugPrint('Dropping unreadable queued change ${op.id}: $e');
        await _queue.remove(op.id);
        continue;
      }

      switch (await _send(change, tempIdToReal)) {
        case _ReplayOutcome.succeeded:
          await _queue.remove(op.id);
        case _ReplayOutcome.conflicted:
          conflicted.add(op);
          await _queue.remove(op.id);
        case _ReplayOutcome.retryLater:
          break;
      }
    }

    return conflicted;
  }

  /// Sends [change] by calling the matching repository method.
  Future<_ReplayOutcome> _send(
    PendingChange change,
    Map<String, String> tempIdToReal,
  ) async => switch (change) {
    ItemCreated() => await _createItem(change, tempIdToReal),
    ItemEdited(:final item) => _outcomeOf(await _itemRepository.save(item)),
    ItemRemoved(:final itemId) => _outcomeOf(
      await _itemRepository.remove(itemId),
    ),
    CheckedItemsCleared(:final listId) => _outcomeOf(
      await _itemRepository.clearChecked(listId),
    ),
    ItemsRemoved(:final listId, :final itemIds) => _outcomeOf(
      await _itemRepository.removeMany(listId, itemIds),
    ),
    ItemsMovedToShop(:final listId, :final itemIds, :final targetShopId) =>
      _outcomeOf(
        await _itemRepository.moveMany(listId, itemIds, targetShopId),
      ),
    ListCreated() => await _createList(change, tempIdToReal),
    ListRenamed(:final listId, :final name) => _outcomeOf(
      await _listRepository.rename(listId, name),
    ),
    ClearCheckedAfterShoppingSet(:final listId, :final value) => _outcomeOf(
      await _listRepository.setClearCheckedAfterShopping(listId, value),
    ),
    ListLeft(:final listId) => _outcomeOf(
      await _listRepository.leave(listId),
    ),
    ListDeleted(:final listId) => _outcomeOf(
      await _listRepository.delete(listId),
    ),
    MemberRemoved(:final listId, :final userId) => _outcomeOf(
      await _listRepository.removeMember(listId, userId),
    ),
    OwnershipTransferred(:final listId, :final userId) => _outcomeOf(
      await _listRepository.transferOwnership(listId, userId),
    ),
  };

  /// Sends an item create; on success, remembers the item's real id.
  Future<_ReplayOutcome> _createItem(
    ItemCreated change,
    Map<String, String> tempIdToReal,
  ) async {
    final result = await _itemRepository.add(
      listId: change.listId,
      name: change.name,
      quantity: change.quantity,
      shopId: change.shopId,
      noteText: change.noteText,
    );
    if (result case Ok(:final value)) {
      tempIdToReal[change.tempId] = value.id.value;
    }
    return _outcomeOf(result);
  }

  /// Sends a list create; on success, remembers the list's real id.
  Future<_ReplayOutcome> _createList(
    ListCreated change,
    Map<String, String> tempIdToReal,
  ) async {
    final result = await _listRepository.create(name: change.name);
    if (result case Ok(:final value)) {
      tempIdToReal[change.tempId] = value.id.value;
    }
    return _outcomeOf(result);
  }
}
