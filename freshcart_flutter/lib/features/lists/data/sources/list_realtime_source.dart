import 'dart:async';

import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/streaming/resilient_watch.dart';
import 'package:freshcart_flutter/features/lists/data/mappers/shopping_list_mapper.dart';
import 'package:freshcart_flutter/features/sync/data/sources/cache/cached_lists_store.dart';
import 'package:freshcart_flutter/features/sync/data/sources/connectivity/connectivity_adapter.dart';

/// Gives live updates for one list.
///
/// Unlike items, the server sends the whole list on every change (not just
/// what changed). A list is one small object, so each update just replaces
/// the old one.
class ListRealtimeSource {
  /// Creates the source against a generated Serverpod [dto.Client].
  const ListRealtimeSource(
    this._client,
    this._connectivityAdapter,
    this._cache,
  );

  final dto.Client _client;
  final ConnectivityAdapter _connectivityAdapter;
  final CachedListsStore _cache;

  /// Sends list [listId] now, and again every time someone changes it
  /// (rename, someone joins or leaves).
  ///
  /// Uses [resilientWatch]: if the connection drops, it keeps the last
  /// value and reconnects when we're back online. Every update is also
  /// saved to [_cache], so the app can show it when starting offline.
  Stream<Result<ShoppingList>> watch(ListId listId) {
    final listUuid = dto.UuidValue.withValidation(listId.value);

    return resilientWatch(
      fetch: () async => (await _client.list.byId(listUuid)).toDomain(),
      watch: () => _client.list.watchList(listUuid),
      reduce: (_, next) => next.toDomain(),
      online: _connectivityAdapter.watchIsOnline,
      // Save to the offline cache, without waiting. If saving fails,
      // ignore it: the cache is only a backup.
      cacheWrite: (list) => unawaited(_cache.upsert(list).catchError((_) {})),
      cacheRead: () => _cache.read(listId),
    );
  }
}
