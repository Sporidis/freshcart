import 'dart:async';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/offline/database/app_database.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_change.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_operations_queue.dart';
import 'package:freshcart_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:freshcart_flutter/features/items/data/repositories/remote_item_repository.dart';
import 'package:freshcart_flutter/features/items/data/sources/queued_item_changes.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'offline_item_repository.g.dart';

/// Watches a list's items on the server; [resync] asks for a fresh fetch
/// while staying subscribed.
typedef WatchServer =
    Stream<Result<List<ShoppingItem>>> Function(
      ListId listId, {
      Stream<void>? resync,
    });

/// An [ItemRepository] that keeps working offline.
///
/// Wraps another [ItemRepository] (the remote one) and passes every call
/// through. Only when that comes back as [NetworkFailure] (the server
/// couldn't be reached) does it step in: it queues the change for later
/// and answers as if it worked, marked `pending`.
class OfflineItemRepository implements ItemRepository {
  OfflineItemRepository(
    this._remote,
    this._queue,
    this._currentUserId, {
    WatchServer? watchServer,
  }) : _watchServer =
           watchServer ?? ((listId, {resync}) => _remote.watchByList(listId));

  final ItemRepository _remote;
  final PendingOperationsQueue _queue;

  /// The server's live items. With a resync, so a change that just left
  /// the queue is fetched again (its live update can be missed).
  final WatchServer _watchServer;

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
    await _queue.enqueue(
      ItemCreated(
        tempId: tempId,
        listId: listId,
        name: name,
        quantity: quantity,
        shopId: shopId,
        noteText: noteText,
      ),
    );
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
  Future<Result<ShoppingItem>> save(ShoppingItem item) async {
    // Made offline and not sent yet: the server doesn't know this item, so
    // the change can only wait in the queue behind its creation.
    if (!_isOnServer(item.id)) {
      await _queue.enqueue(ItemEdited(item));
      return Ok(item.copyWith(pending: true));
    }
    final result = await _remote.save(item);
    if (!_isOffline(result)) return result;
    await _queue.enqueue(ItemEdited(item));
    return Ok(item.copyWith(pending: true));
  }

  @override
  Future<Result<void>> remove(ItemId id) async {
    if (!_isOnServer(id)) {
      await _queue.enqueue(ItemRemoved(id));
      return const Ok(null);
    }
    final result = await _remote.remove(id);
    if (!_isOffline(result)) return result;
    await _queue.enqueue(ItemRemoved(id));
    return const Ok(null);
  }

  // The bulk writes answer 0 when queued: how many rows change is only
  // known once the server runs them.

  @override
  Future<Result<int>> clearChecked(ListId listId) async {
    final result = await _remote.clearChecked(listId);
    if (!_isOffline(result)) return result;
    await _queue.enqueue(CheckedItemsCleared(listId));
    return const Ok(0);
  }

  @override
  Future<Result<int>> removeMany(ListId listId, List<ItemId> ids) async {
    final result = await _remote.removeMany(listId, ids);
    if (!_isOffline(result)) return result;
    await _queue.enqueue(ItemsRemoved(listId, ids));
    return const Ok(0);
  }

  @override
  Future<Result<int>> moveMany(
    ListId listId,
    List<ItemId> ids,
    ShopId? shopId,
  ) async {
    final result = await _remote.moveMany(listId, ids, shopId);
    if (!_isOffline(result)) return result;
    await _queue.enqueue(ItemsMovedToShop(listId, ids, shopId));
    return const Ok(0);
  }

  // ── Reads: pass through ──────────────────────────────────────────────

  @override
  Future<Result<List<ShoppingItem>>> byList(ListId listId) =>
      _remote.byList(listId);

  /// The list's items, live, with the changes still waiting in the queue
  /// applied on top (see [applyQueuedItemChanges]). Re-sent whenever
  /// either side changes: a server update, or the queue growing or
  /// replaying.
  @override
  Stream<Result<List<ShoppingItem>>> watchByList(ListId listId) {
    // When a queued change leaves the queue it has reached the server, but
    // its live update can be missed, so the server side fetches again.
    final resync = StreamController<void>.broadcast();
    final server = _watchServer(listId, resync: resync.stream);

    StreamSubscription<Result<List<ShoppingItem>>>? serverSub;
    StreamSubscription<List<PendingOperation>>? queueSub;
    Result<List<ShoppingItem>>? latest;
    var queued = const <PendingOperation>[];
    late final StreamController<Result<List<ShoppingItem>>> out;

    void emit() {
      final current = latest;
      // Nothing from the server or cache yet: wait, rather than show a
      // list made only of queued changes.
      if (current == null || out.isClosed) return;
      out.add(_withQueued(current, queued, listId));
    }

    out = StreamController<Result<List<ShoppingItem>>>(
      onListen: () {
        serverSub = server.listen(
          (event) {
            latest = event;
            emit();
          },
          onError: out.addError,
          onDone: out.close,
        );
        queueSub = _queue.watchAll().listen(
          (ops) {
            // An empty queue that was already empty changes nothing on
            // screen: don't send the same list twice.
            final changed = ops.isNotEmpty || queued.isNotEmpty;
            final synced = ops.length < queued.length;
            queued = ops;
            if (changed) emit();
            if (synced) resync.add(null);
          },
          // The queue is only an overlay: if reading it fails, keep
          // showing the server's items as they are.
          onError: (Object _) {},
        );
      },
      onCancel: () async {
        await queueSub?.cancel();
        await serverSub?.cancel();
        await resync.close();
      },
    );
    return out.stream;
  }

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

  /// What the screen gets for [listId]: the server's (or cache's) items
  /// [current], with the [queued] changes for this list applied on top.
  ///
  /// When the server couldn't be reached and nothing was cached (a new
  /// account, or right after signing out), [current] is a network failure.
  /// If changes for this list are waiting in the queue, those should still
  /// show, as pending items on an otherwise empty list, rather than an
  /// error page hiding them. Any other failure (not a member any more, the
  /// list was deleted) still shows as itself.
  Result<List<ShoppingItem>> _withQueued(
    Result<List<ShoppingItem>> current,
    List<PendingOperation> queued,
    ListId listId,
  ) {
    if (current case Err(failure: NetworkFailure())) {
      final items = applyQueuedItemChanges(
        const [],
        queued,
        listId,
        me: _currentUserId,
      );
      return items.isEmpty ? current : Ok(items);
    }
    return current.map(
      (items) => applyQueuedItemChanges(
        items,
        queued,
        listId,
        me: _currentUserId,
      ),
    );
  }

  /// A temporary id for something created offline, until the server gives
  /// it a real one.
  static String _newTempId() =>
      '$_tempPrefix${DateTime.now().microsecondsSinceEpoch}';

  static const String _tempPrefix = 'temp-';

  /// Whether the server knows [id] yet: not while it's a temporary id from
  /// an add still waiting in the queue. Changes to such an item are queued
  /// behind its creation; the replayer swaps in the real id (`withRealIds`).
  static bool _isOnServer(ItemId id) => !id.value.startsWith(_tempPrefix);
}

/// Supplies the app's [ItemRepository]: the server, kept working offline.
@Riverpod(keepAlive: true)
ItemRepository itemRepository(Ref ref) {
  final remote = ref.watch(remoteItemRepositoryProvider);
  return OfflineItemRepository(
    remote,
    ref.watch(pendingOperationsQueueProvider),
    () =>
        ref.read(authRepositoryProvider).sessionUserId ??
        (throw StateError(
          'sessionUserId not resolved — no session found at all',
        )),
    watchServer: remote.watchServer,
  );
}
