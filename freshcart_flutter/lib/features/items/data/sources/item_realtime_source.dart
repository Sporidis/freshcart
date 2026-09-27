import 'dart:async';

import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/streaming/resilient_watch.dart';
import 'package:freshcart_flutter/features/items/data/mappers/shopping_item_mapper.dart';
import 'package:freshcart_flutter/features/sync/data/sources/cache/cached_items_store.dart';
import 'package:freshcart_flutter/features/sync/data/sources/connectivity/connectivity_adapter.dart';

/// Turns the server's change deltas into a live list of items.
///
/// The wire carries one [dto.ItemChange] per edit, because a list can hold
/// hundreds of items and a change usually touches one. Keeping the merged list
/// is therefore the client's job, and this is where that happens — above the
/// transport, below anything that knows what a widget is.
class ItemRealtimeSource {
  /// Creates the source against a generated Serverpod [dto.Client].
  const ItemRealtimeSource(
    this._client,
    this._connectivityAdapter,
    this._cache,
  );

  final dto.Client _client;
  final ConnectivityAdapter _connectivityAdapter;
  final CachedItemsStore _cache;

  /// Emits the full list of items on [listId], re-emitting on every change.
  ///
  /// Seeds with a normal fetch, then applies deltas. A dropped connection no
  /// longer ends this stream: [resilientWatch] keeps the last good value and
  /// reconnects transparently once [ConnectivityAdapter] reports we're back
  /// online (see `docs/offline-sync-plan.md` Phase F). Every snapshot is also
  /// written through to [_cache], and a cold start with no connection falls
  /// back to reading it (§4's "cached reads") instead of failing outright.
  Stream<Result<List<ShoppingItem>>> watchByList(ListId listId) {
    final listUuid = dto.UuidValue.withValidation(listId.value);

    return resilientWatch(
      fetch: () async => List<ShoppingItem>.unmodifiable(
        (await _client.item.byList(listUuid)).map((i) => i.toDomain()),
      ),
      watch: () => _client.item.watchList(listUuid),
      reduce: (current, event) =>
          List<ShoppingItem>.unmodifiable(applyChange(current, event)),
      online: _connectivityAdapter.watchIsOnline,
      // Best-effort: a failed write here (e.g. the app closing the database
      // mid-write) must not surface as an uncaught error on a stream nobody
      // awaits this against -- the live watch above already has its value,
      // cached reads are only a fallback for a cold offline start.
      cacheWrite: (items) =>
          unawaited(_cache.replaceForList(listId, items).catchError((_) {})),
      cacheRead: () => _cache.readForList(listId),
    );
  }

  /// Merges one change into [current].
  ///
  /// Exposed for testing: the merge is the part with the rules in it, and it is
  /// worth pinning without a socket. An upsert for an unknown id appends, which
  /// is how another person's new item arrives.
  static List<ShoppingItem> applyChange(
    List<ShoppingItem> current,
    dto.ItemChange change,
  ) {
    final id = ItemId(change.itemId.uuid);
    switch (change.kind) {
      case dto.ItemChangeKind.removed:
        return [
          for (final item in current)
            if (item.id != id) item,
        ];
      case dto.ItemChangeKind.upserted:
        final incoming = change.item?.toDomain();
        // An upsert with no payload is a malformed event; dropping it is safer
        // than guessing, and the next full read will correct the list.
        if (incoming == null) return current;
        final known = current.any((item) => item.id == id);
        if (!known) return [...current, incoming];
        return [
          for (final item in current)
            if (item.id == id) incoming else item,
        ];
    }
  }
}
