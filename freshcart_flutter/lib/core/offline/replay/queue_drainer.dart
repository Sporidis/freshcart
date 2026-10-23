import 'dart:convert';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/offline/database/app_database.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_operations_queue.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_operations_table.dart';
import 'package:freshcart_flutter/core/offline/queue/shopping_item_queue_payload.dart';

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
class QueueDrainer {
  const QueueDrainer(this._queue, this._itemRepository, this._listRepository);

  final PendingOperationsQueue _queue;
  final ItemRepository _itemRepository;
  final ListRepository _listRepository;

  /// Sends every queued change, oldest first.
  ///
  /// Returns the changes that were dropped because of a conflict, so the
  /// app can tell the user. Changes that failed for other reasons stay in
  /// the queue.
  Future<List<PendingOperation>> drain() async {
    final ops = await _queue.getAll();
    // Temporary id -> real id from the server, filled in as "create"
    // operations succeed. Later changes to the same item use it.
    final tempIdToReal = <String, String>{};
    final conflicted = <PendingOperation>[];

    for (final op in ops) {
      final payload = jsonDecode(op.payload) as Map<String, dynamic>;
      _rewriteTempIds(payload, tempIdToReal);

      final outcome = switch (op.entityType) {
        PendingEntityType.item => await _replayItem(
          op,
          payload,
          tempIdToReal,
        ),
        PendingEntityType.list => await _replayList(
          op,
          payload,
          tempIdToReal,
        ),
      };

      switch (outcome) {
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

  /// After a successful create, remembers which real id belongs to the
  /// temporary id.
  void _rememberRealId(
    PendingOperation op,
    Result<({String id})> result,
    Map<String, String> tempIdToReal,
  ) {
    if (op.tempId == null) return;
    switch (result) {
      case Ok(:final value):
        tempIdToReal[op.tempId!] = value.id;
      case Err():
        break;
    }
  }

  /// Sends one item change by calling the matching [ItemRepository] method.
  Future<_ReplayOutcome> _replayItem(
    PendingOperation op,
    Map<String, dynamic> payload,
    Map<String, String> tempIdToReal,
  ) async {
    switch (op.opType) {
      case PendingOpType.create:
        final result = await _itemRepository.add(
          listId: ListId(payload['listId'] as String),
          name: payload['name'] as String,
          quantity: payload['quantity'] as int,
          shopId: payload['shopId'] == null
              ? null
              : ShopId(payload['shopId'] as String),
          noteText: payload['noteText'] as String?,
        );
        _rememberRealId(
          op,
          result.map((value) => (id: value.id.value)),
          tempIdToReal,
        );
        return _outcomeOf(result);

      case PendingOpType.remove:
        return _outcomeOf(
          await _itemRepository.remove(ItemId(payload['itemId'] as String)),
        );

      case PendingOpType.edit:
        return _outcomeOf(
          await _itemRepository.save(shoppingItemFromQueuePayload(payload)),
        );

      case PendingOpType.clearChecked:
        return _outcomeOf(
          await _itemRepository.clearChecked(
            ListId(payload['listId'] as String),
          ),
        );

      case PendingOpType.moveMany:
        return _outcomeOf(
          await _itemRepository.moveMany(
            ListId(payload['listId'] as String),
            [
              for (final id in payload['ids'] as List<dynamic>)
                ItemId(id as String),
            ],
            payload['shopId'] == null
                ? null
                : ShopId(payload['shopId'] as String),
          ),
        );

      case PendingOpType.removeMany:
        return _outcomeOf(
          await _itemRepository.removeMany(
            ListId(payload['listId'] as String),
            [
              for (final id in payload['ids'] as List<dynamic>)
                ItemId(id as String),
            ],
          ),
        );

      default:
        return _ReplayOutcome.retryLater;
    }
  }

  /// Sends one list change by calling the matching [ListRepository] method.
  Future<_ReplayOutcome> _replayList(
    PendingOperation op,
    Map<String, dynamic> payload,
    Map<String, String> tempIdToReal,
  ) async {
    switch (op.opType) {
      case PendingOpType.create:
        final result = await _listRepository.create(
          name: payload['name'] as String,
        );
        _rememberRealId(
          op,
          result.map((value) => (id: value.id.value)),
          tempIdToReal,
        );
        return _outcomeOf(result);

      case PendingOpType.rename:
        return _outcomeOf(
          await _listRepository.rename(
            ListId(payload['id'] as String),
            payload['name'] as String,
          ),
        );

      case PendingOpType.setClearCheckedAfterShopping:
        return _outcomeOf(
          await _listRepository.setClearCheckedAfterShopping(
            ListId(payload['id'] as String),
            payload['value'] as bool,
          ),
        );

      case PendingOpType.transferOwnership:
        return _outcomeOf(
          await _listRepository.transferOwnership(
            ListId(payload['id'] as String),
            UserId(payload['userId'] as String),
          ),
        );

      case PendingOpType.leave:
        return _outcomeOf(
          await _listRepository.leave(ListId(payload['id'] as String)),
        );

      case PendingOpType.delete:
        return _outcomeOf(
          await _listRepository.delete(ListId(payload['id'] as String)),
        );

      case PendingOpType.removeMember:
        return _outcomeOf(
          await _listRepository.removeMember(
            ListId(payload['id'] as String),
            UserId(payload['userId'] as String),
          ),
        );

      default:
        return _ReplayOutcome.retryLater;
    }
  }
}

/// Replaces temporary ids in [payload] with the real ids from the server.
///
/// Example: offline you add "Milk" (temp id) and then check it. When we
/// send the "check", it must use Milk's real id.
void _rewriteTempIds(
  Map<String, dynamic> payload,
  Map<String, String> tempIdToReal,
) {
  // 'itemId': the item being changed.
  // 'listId': the list an item is in (that list may also be new).
  // 'id':     the list being changed.
  for (final key in ['itemId', 'listId', 'id']) {
    final value = payload[key];
    if (value != null && tempIdToReal.containsKey(value)) {
      payload[key] = tempIdToReal[value]!;
    }
  }
}
