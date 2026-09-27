import 'dart:async';

import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';
import 'package:freshcart_flutter/features/items/data/mappers/name_history_entry_mapper.dart';
import 'package:freshcart_flutter/features/items/data/mappers/shopping_item_mapper.dart';
import 'package:freshcart_flutter/features/items/data/sources/item_realtime_source.dart';
import 'package:freshcart_flutter/features/sync/data/sources/cache/cached_items_store.dart';
import 'package:freshcart_flutter/features/sync/data/sources/connectivity/connectivity_adapter.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/pending_operations_queue.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/pending_operations_table.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/shopping_item_queue_payload.dart';

/// The Serverpod-backed [ItemRepository].
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

  /// The signed-in user's id, read lazily so it reflects whatever
  /// `currentUserIdProvider` has cached at the moment it's needed — not
  /// resolved once when this repository is constructed.
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
      // Minted once, reused for both the queue row and the fabricated item's
      // id — they must be the same value, or a later queued op (e.g. a
      // toggle on this same item, still offline) has nothing to reference.
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

  @override
  Stream<Result<List<ShoppingItem>>> watchByList(ListId listId) =>
      ItemRealtimeSource(
        _client,
        _connectivityAdapter,
        _cache,
      ).watchByList(listId);

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
