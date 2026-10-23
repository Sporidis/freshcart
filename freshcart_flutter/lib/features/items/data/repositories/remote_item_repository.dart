import 'dart:async';

import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/di/serverpod_client_provider.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';
import 'package:freshcart_flutter/core/offline/cache/cached_items_store.dart';
import 'package:freshcart_flutter/core/offline/connectivity/connectivity_adapter.dart';
import 'package:freshcart_flutter/features/items/data/mappers/name_history_entry_mapper.dart';
import 'package:freshcart_flutter/features/items/data/mappers/shopping_item_mapper.dart';
import 'package:freshcart_flutter/features/items/data/sources/item_realtime_source.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'remote_item_repository.g.dart';

/// The [ItemRepository] that only talks to the Serverpod server.
///
/// Serverpod types (`dto.`) come in, domain types go out. When the server
/// can't be reached the result is `Err(Failure.network)`: deciding what
/// to do about that (queue it for later) is the offline layer's job.
class RemoteItemRepository implements ItemRepository {
  const RemoteItemRepository(
    this._client,
    this._connectivityAdapter,
    this._cache,
  );

  final dto.Client _client;
  final ConnectivityAdapter _connectivityAdapter;
  final CachedItemsStore _cache;

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
  );

  @override
  Future<Result<ShoppingItem>> save(ShoppingItem item) =>
      _guard(() async => (await _client.item.save(item.toDto())).toDomain());

  @override
  Future<Result<void>> remove(ItemId id) =>
      _guard(() => _client.item.remove(_uuid(id.value)));

  @override
  Future<Result<int>> clearChecked(ListId listId) =>
      _guard(() => _client.item.clearChecked(_uuid(listId.value)));

  @override
  Future<Result<int>> removeMany(ListId listId, List<ItemId> ids) => _guard(
    () => _client.item.removeMany(
      _uuid(listId.value),
      [for (final id in ids) _uuid(id.value)],
    ),
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
  );

  /// The list's items, live from the server (cached for when it's gone).
  @override
  Stream<Result<List<ShoppingItem>>> watchByList(ListId listId) =>
      watchServer(listId);

  /// [watchByList], re-fetching whenever [resync] fires (a change that
  /// reached the server whose live update may have been missed).
  Stream<Result<List<ShoppingItem>>> watchServer(
    ListId listId, {
    Stream<void>? resync,
  }) => ItemRealtimeSource(
    _client,
    _connectivityAdapter,
    _cache,
  ).watchByList(listId, resync: resync);

  @override
  Future<Result<List<String>>> suggestNames(ListId listId, String query) =>
      _guard(() => _client.item.suggestNames(_uuid(listId.value), query));

  @override
  Future<Result<List<NameHistoryEntry>>> recentNames(ListId listId) => _guard(
    () async => (await _client.item.recentNames(
      _uuid(listId.value),
    )).map((e) => e.toDomain()).toList(),
  );

  static dto.UuidValue _uuid(String value) =>
      dto.UuidValue.withValidation(value);

  static Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Ok(await retryOnUnreachable(body, maxAttempts: 2));
    } on Object catch (error) {
      return Err(mapExceptionToFailure(error));
    }
  }
}

/// Supplies the [RemoteItemRepository]: what the offline queue is
/// replayed through, so a replay can never queue itself again.
@Riverpod(keepAlive: true)
RemoteItemRepository remoteItemRepository(Ref ref) => RemoteItemRepository(
  ref.watch(serverpodClientProvider),
  ref.watch(connectivityAdapterProvider),
  ref.watch(cachedItemsStoreProvider),
);
