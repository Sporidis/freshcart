import 'dart:convert';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/sync/data/database/app_database.dart';
import 'package:freshcart_flutter/features/sync/data/queue/pending_operations_queue.dart';
import 'package:freshcart_flutter/features/sync/data/queue/pending_operations_table.dart';
import 'package:freshcart_flutter/features/sync/data/queue/shopping_item_queue_payload.dart';

/// What happened when a single queued write was replayed.
enum _ReplayOutcome {
  /// The server accepted it — safe to remove from the queue.
  succeeded,

  /// The server rejected it as a conflict. Per offline-sync-plan.md Phase D's
  /// "server wins" decision: dropped, not retried or force-applied — but
  /// reported back so the caller can tell the user what didn't make it.
  conflicted,

  /// Any other failure (still unreachable, validation, unexpected...) —
  /// left queued to try again on the next reconnect, rather than lost.
  retryLater,
}

_ReplayOutcome _outcomeOf(Result<Object?> result) => switch (result) {
  Ok() => _ReplayOutcome.succeeded,
  Err(failure: ConflictFailure()) => _ReplayOutcome.conflicted,
  Err() => _ReplayOutcome.retryLater,
};

/// Replays writes that were queued while offline, once the server is
/// reachable again (offline-sync-plan.md Phase D).
class QueueDrainer {
  const QueueDrainer(this._queue, this._itemRepository, this._listRepository);

  final PendingOperationsQueue _queue;
  final ItemRepository _itemRepository;
  final ListRepository _listRepository;

  /// Drains every queued write, oldest first, replaying each against the
  /// real repositories.
  ///
  /// Returns every op the server rejected as a conflict — dropped here, but
  /// it's Phase E's job to actually show the user something about them; this
  /// layer only decides and reports. Anything that fails for another reason
  /// stays in the queue rather than being lost.
  Future<List<PendingOperation>> drain() async {
    final ops = await _queue.getAll();
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

  /// Records `op.tempId`'s real id once a `create` succeeds, if it had one.
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

void _rewriteTempIds(
  Map<String, dynamic> payload,
  Map<String, String> tempIdToReal,
) {
  // 'itemId' — an item op referencing itself (edit/remove/etc.).
  // 'listId' — an item op referencing the list it belongs to, when that
  //            list was itself created offline (add an item to a
  //            not-yet-real list, still offline).
  // 'id'     — a list op referencing itself (rename/leave/delete/...).
  for (final key in ['itemId', 'listId', 'id']) {
    final value = payload[key];
    if (value != null && tempIdToReal.containsKey(value)) {
      payload[key] = tempIdToReal[value]!;
    }
  }
}
