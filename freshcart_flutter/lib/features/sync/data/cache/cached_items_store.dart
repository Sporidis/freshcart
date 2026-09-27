import 'dart:convert';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/sync/data/database/app_database.dart';
import 'package:freshcart_flutter/features/sync/data/queue/shopping_item_queue_payload.dart';

/// Persists the last-known items of one list, so
/// `ItemRealtimeSource.watchByList` has something to show when the very
/// first fetch fails offline (`docs/offline-sync-plan.md` §4's "cached
/// reads"). Reuses [ShoppingItemQueuePayload]'s JSON codec -- already a
/// lossless full-entity round-trip, built for the offline queue's `edit`
/// payload, and just as good a fit here.
///
/// See [CachedListsStore]'s doc comment for the accepted cache-miss vs.
/// confirmed-empty tradeoff -- the same one applies per list here.
class CachedItemsStore {
  const CachedItemsStore(this._db);

  final AppDatabase _db;

  /// Replaces every cached item for [listId] with [items] -- always the
  /// complete, authoritative set for that list, same reasoning as
  /// [CachedListsStore.replaceAll].
  Future<void> replaceForList(ListId listId, List<ShoppingItem> items) =>
      _db.transaction(() async {
        await (_db.delete(
          _db.cachedItems,
        )..where((row) => row.listId.equals(listId.value))).go();
        final now = DateTime.now();
        for (final item in items) {
          await _db
              .into(_db.cachedItems)
              .insert(
                CachedItemsCompanion.insert(
                  itemId: item.id.value,
                  listId: listId.value,
                  data: jsonEncode(item.toQueuePayload()),
                  cachedAt: now,
                ),
              );
        }
      });

  /// The cached items of [listId], or `null` if that list was never cached.
  Future<List<ShoppingItem>?> readForList(ListId listId) async {
    final rows = await (_db.select(
      _db.cachedItems,
    )..where((row) => row.listId.equals(listId.value))).get();
    if (rows.isEmpty) return null;
    return [
      for (final row in rows)
        shoppingItemFromQueuePayload(
          jsonDecode(row.data) as Map<String, dynamic>,
        ),
    ];
  }
}
