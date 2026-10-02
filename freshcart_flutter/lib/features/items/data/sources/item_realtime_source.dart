import 'dart:async';

import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/streaming/resilient_watch.dart';
import 'package:freshcart_flutter/features/items/data/mappers/shopping_item_mapper.dart';
import 'package:freshcart_flutter/features/sync/data/sources/cache/cached_items_store.dart';
import 'package:freshcart_flutter/features/sync/data/sources/connectivity/connectivity_adapter.dart';

/// Gives a live list of items for one list.
///
/// The server only sends what changed ([dto.ItemChange]), not the whole
/// list, because a list can have hundreds of items and a change usually
/// touches one. This class applies each change to the full list.
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

  /// Sends all items of [listId] now, and again after every change.
  ///
  /// First loads everything, then applies changes one by one. Uses
  /// [resilientWatch]: if the connection drops, it keeps the last items and
  /// reconnects when we're back online. Every update is also saved to
  /// [_cache], so the app can show it when starting offline.
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
      // Save to the offline cache, without waiting. If saving fails,
      // ignore it: the cache is only a backup.
      cacheWrite: (items) =>
          unawaited(_cache.replaceForList(listId, items).catchError((_) {})),
      cacheRead: () => _cache.readForList(listId),
    );
  }

  /// Applies one change to [current] and returns the new list.
  ///
  /// Public so it can be tested without a real connection. An update for an
  /// id we don't have yet is added at the end (that's how someone else's
  /// new item arrives).
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
        // An update without the item is broken. Ignore it; the next full
        // load will fix the list.
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
