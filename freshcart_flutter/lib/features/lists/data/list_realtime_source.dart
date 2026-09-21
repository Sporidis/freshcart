import 'dart:async';

import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/streaming/resilient_watch.dart';
import 'package:freshcart_flutter/features/lists/data/mappers/shopping_list_mapper.dart';
import 'package:freshcart_flutter/features/sync/data/cached_lists_store.dart';
import 'package:freshcart_flutter/features/sync/data/connectivity_adapter.dart';

/// Turns the server's list broadcasts into a live view of one list.
///
/// Unlike the item source, the wire carries the whole [dto.ShoppingList]
/// on every change rather than a delta: a list is a single row, not a
/// collection that could run to hundreds, so there is nothing to merge. Each
/// event simply replaces what was there.
class ListRealtimeSource {
  /// Creates the source against a generated Serverpod [dto.Client].
  const ListRealtimeSource(this._client, this._connectivityAdapter, this._cache);

  final dto.Client _client;
  final ConnectivityAdapter _connectivityAdapter;
  final CachedListsStore _cache;

  /// Emits the current state of [listId], re-emitting whenever anyone changes
  /// it — a rename, a join, a member leaving.
  ///
  /// Seeds with a normal fetch, then follows the stream. A dropped
  /// connection no longer ends this stream: [resilientWatch] keeps the last
  /// good value and reconnects transparently once [ConnectivityAdapter]
  /// reports we're back online (see `docs/offline-sync-plan.md` Phase F).
  /// Every snapshot is also written through to [_cache], and a cold start
  /// with no connection falls back to reading it (§4's "cached reads")
  /// instead of failing outright.
  Stream<Result<ShoppingList>> watch(ListId listId) {
    final listUuid = dto.UuidValue.withValidation(listId.value);

    return resilientWatch(
      fetch: () async => (await _client.list.byId(listUuid)).toDomain(),
      watch: () => _client.list.watchList(listUuid),
      reduce: (_, next) => next.toDomain(),
      online: _connectivityAdapter.watchIsOnline,
      cacheWrite: (list) => unawaited(_cache.upsert(list)),
      cacheRead: () => _cache.read(listId),
    );
  }
}
