import 'dart:convert';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/sync/data/sources/database/app_database.dart';
import 'package:freshcart_flutter/features/sync/data/sources/database/app_database_provider.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/shopping_item_queue_payload.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cached_items_store.g.dart';

/// Saves each list's items on the phone, so they can still be shown when
/// the app opens without internet.
///
/// Items are stored as JSON, using the same conversion as the offline
/// queue ([ShoppingItemQueuePayload]).
///
/// Same limitation as [CachedListsStore]: "never saved" and "saved, but
/// empty" both read back as `null`.
class CachedItemsStore {
  const CachedItemsStore(this._db);

  final AppDatabase _db;

  /// Deletes the saved items of [listId] and saves [items] instead.
  /// [items] must be the full list from the server, not just some of them.
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

  /// The saved items of [listId], or `null` if there are none.
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

/// Supplies the [CachedItemsStore], backed by [appDatabaseProvider].
@Riverpod(keepAlive: true)
CachedItemsStore cachedItemsStore(Ref ref) =>
    CachedItemsStore(ref.watch(appDatabaseProvider));
