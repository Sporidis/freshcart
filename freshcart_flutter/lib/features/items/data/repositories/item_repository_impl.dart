import 'dart:async';

import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/di/serverpod_client_provider.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';
import 'package:freshcart_flutter/features/auth/data/sources/current_user_provider.dart';
import 'package:freshcart_flutter/features/items/data/mappers/name_history_entry_mapper.dart';
import 'package:freshcart_flutter/features/items/data/mappers/shopping_item_mapper.dart';
import 'package:freshcart_flutter/features/items/data/sources/item_realtime_source.dart';
import 'package:freshcart_flutter/features/sync/data/sources/cache/cached_items_store.dart';
import 'package:freshcart_flutter/features/sync/data/sources/connectivity/connectivity_adapter.dart';
import 'package:freshcart_flutter/features/sync/data/sources/database/app_database.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/pending_operations_queue.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/pending_operations_table.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/queued_item_changes.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/shopping_item_queue_payload.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'item_repository_impl.g.dart';

/// The real [ItemRepository], talking to the Serverpod server.
class ItemRepositoryImpl implements ItemRepository {
  /// Creates the repository against a generated Serverpod [dto.Client].
  const ItemRepositoryImpl(
    this._client,
    this.queue,
    this._connectivityAdapter,
    this.currentUserId,
    this._cache,
  );

  final dto.Client _client;
  final PendingOperationsQueue queue;
  final CachedItemsStore _cache;

  /// The signed-in user's id. Read each time it's needed (not once when
  /// the repository is created), so it's always the current one.
  final UserId Function() currentUserId;

  final ConnectivityAdapter _connectivityAdapter;

  @override
  Future<Result<List<ShoppingItem>>> byList(ListId listId) => _guard(
    () async => (await _client.item.byList(
      _uuid(listId.value),
    )).map((i) => i.toDomain()).toList(),
  );

  @override
  Future<Result<ShoppingItem>> add({
    required ListId listId,
    required String name,
    int quantity = 1,
    ShopId? shopId,
    String? noteText,
  }) => _guard(
    () async => (await _client.item.add(
      _uuid(listId.value),
      name,
      quantity: quantity,
      shopId: shopId == null ? null : _uuid(shopId.value),
      noteText: noteText,
    )).toDomain(),
    onUnreachable: () async {
      // One temporary id, used for both the queue and the item shown on
      // screen. They must match, so later offline changes to this item
      // (like checking it) point to the right one.
      final tempId = _mintTempId();
      final userId = currentUserId();
      final now = DateTime.now().toUtc();

      await queue.enqueue(
        entityType: PendingEntityType.item,
        opType: PendingOpType.create,
        tempId: tempId,
        payload: <String, dynamic>{
          'listId': listId.value,
          'name': name,
          'quantity': quantity,
          'shopId': shopId?.value,
          'noteText': noteText,
        },
      );

      return ShoppingItem(
        id: ItemId(tempId),
        listId: listId,
        name: name,
        addedBy: userId,
        createdAt: now,
        updatedAt: now,
        quantity: quantity,
        shopId: shopId,
        note: noteText == null || noteText.trim().isEmpty
            ? null
            : Note(text: noteText, authorId: userId, updatedAt: now),
        pending: true,
      );
    },
  );

  @override
  Future<Result<ShoppingItem>> save(ShoppingItem item) => _guard(
    () async => (await _client.item.save(item.toDto())).toDomain(),
    onUnreachable: () async {
      await queue.enqueue(
        entityType: PendingEntityType.item,
        opType: PendingOpType.edit,
        payload: item.toQueuePayload(),
      );
      return item.copyWith(pending: true);
    },
  );

  @override
  Future<Result<void>> remove(ItemId id) => _guard(
    () => _client.item.remove(_uuid(id.value)),
    onUnreachable: () async {
      await queue.enqueue(
        entityType: PendingEntityType.item,
        opType: PendingOpType.remove,
        payload: {
          'itemId': id.value,
        },
      );
    },
  );

  @override
  Future<Result<int>> clearChecked(ListId listId) => _guard(
    () => _client.item.clearChecked(_uuid(listId.value)),
    onUnreachable: () async {
      final tempId = _mintTempId();
      await queue.enqueue(
        entityType: PendingEntityType.item,
        opType: PendingOpType.clearChecked,
        tempId: tempId,
        payload: {
          'listId': listId.value,
        },
      );
      return 0;
    },
  );

  @override
  Future<Result<int>> removeMany(ListId listId, List<ItemId> ids) => _guard(
    () => _client.item.removeMany(
      _uuid(listId.value),
      [for (final id in ids) _uuid(id.value)],
    ),
    onUnreachable: () async {
      final tempId = _mintTempId();
      await queue.enqueue(
        entityType: PendingEntityType.item,
        opType: PendingOpType.removeMany,
        tempId: tempId,
        payload: {
          'listId': listId.value,
          'ids': [for (final id in ids) id.value],
        },
      );
      return 0;
    },
  );

  @override
  Future<Result<int>> moveMany(
    ListId listId,
    List<ItemId> ids,
    ShopId? shopId,
  ) => _guard(
    () => _client.item.moveMany(
      _uuid(listId.value),
      [for (final id in ids) _uuid(id.value)],
      shopId == null ? null : _uuid(shopId.value),
    ),
    onUnreachable: () async {
      final tempId = _mintTempId();
      await queue.enqueue(
        entityType: PendingEntityType.item,
        opType: PendingOpType.moveMany,
        tempId: tempId,
        payload: {
          'listId': listId.value,
          'ids': [for (final id in ids) id.value],
          'shopId': shopId?.value,
        },
      );
      return 0;
    },
  );

  /// The list's items, live, with the changes still waiting in the offline
  /// queue applied on top (see [applyQueuedItemChanges]). Re-sent whenever
  /// either side changes: a server update, or the queue growing or
  /// draining.
  @override
  Stream<Result<List<ShoppingItem>>> watchByList(ListId listId) {
    final server = ItemRealtimeSource(
      _client,
      _connectivityAdapter,
      _cache,
    ).watchByList(listId);

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
      out.add(
        current.map(
          (items) => applyQueuedItemChanges(
            items,
            queued,
            listId,
            me: currentUserId,
          ),
        ),
      );
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
        queueSub = queue.watchAll().listen(
          (ops) {
            // An empty queue that was already empty changes nothing on
            // screen: don't send the same list twice.
            final changed = ops.isNotEmpty || queued.isNotEmpty;
            queued = ops;
            if (changed) emit();
          },
          // The queue is only an overlay: if reading it fails, keep
          // showing the server's items as they are.
          onError: (Object _) {},
        );
      },
      onCancel: () async {
        await queueSub?.cancel();
        await serverSub?.cancel();
      },
    );
    return out.stream;
  }

  @override
  Future<Result<List<String>>> suggestNames(ListId listId, String query) =>
      _guard(
        () => _client.item.suggestNames(_uuid(listId.value), query),
      );

  @override
  Future<Result<List<NameHistoryEntry>>> recentNames(ListId listId) => _guard(
    () async => (await _client.item.recentNames(
      _uuid(listId.value),
    )).map((e) => e.toDomain()).toList(),
  );

  static dto.UuidValue _uuid(String value) =>
      dto.UuidValue.withValidation(value);

  static Future<Result<T>> _guard<T>(
    Future<T> Function() body, {
    Future<T> Function()? onUnreachable,
  }) async {
    try {
      return Ok(await retryOnUnreachable(body, maxAttempts: 2));
    } on Object catch (error) {
      if (isUnreachable(error) && onUnreachable != null) {
        return Ok(await onUnreachable());
      }
      return Err(mapExceptionToFailure(error));
    }
  }

  String _mintTempId() => 'temp-${DateTime.now().microsecondsSinceEpoch}';
}

/// Supplies the [ItemRepository].
@Riverpod(keepAlive: true)
ItemRepository itemRepository(Ref ref) => ItemRepositoryImpl(
  ref.watch(serverpodClientProvider),
  ref.watch(pendingOperationsQueueProvider),
  ref.watch(connectivityAdapterProvider),
  () =>
      ref.read(currentUserIdProvider).asData?.value.valueOrNull ??
      (throw StateError(
        'currentUserId not resolved — cannot queue an offline add without a known user',
      )),
  ref.watch(cachedItemsStoreProvider),
);
