import 'dart:convert';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/offline/database/app_database.dart';
import 'package:freshcart_flutter/core/offline/database/app_database_provider.dart';
import 'package:freshcart_flutter/core/offline/queue/shopping_item_queue_payload.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cached_items_store.g.dart';

/// Saves each list's items on the phone, so they can still be shown when
/// the app opens without internet.
///
/// Items are stored as JSON, using the same conversion as the offline
/// queue ([ShoppingItemQueuePayload]), one row per list
/// (`CachedListItems`). So a list saved as empty reads back as empty, and
/// only a list that was never saved reads back as `null`.
class CachedItemsStore {
  const CachedItemsStore(this._db);

  final AppDatabase _db;

  /// Saves [items] as the items of [listId], replacing what was saved.
  /// [items] must be the full list from the server, not just some of them.
  Future<void> replaceForList(ListId listId, List<ShoppingItem> items) => _db
      .into(_db.cachedListItems)
      .insertOnConflictUpdate(
        CachedListItemsCompanion.insert(
          listId: listId.value,
          data: jsonEncode([for (final item in items) item.toQueuePayload()]),
          cachedAt: DateTime.now(),
        ),
      );

  /// The saved items of [listId]: empty if it was saved with no items,
  /// `null` if it was never saved.
  Future<List<ShoppingItem>?> readForList(ListId listId) async {
    final row = await (_db.select(
      _db.cachedListItems,
    )..where((row) => row.listId.equals(listId.value))).getSingleOrNull();
    if (row == null) return null;
    return [
      for (final entry in jsonDecode(row.data) as List<dynamic>)
        shoppingItemFromQueuePayload(entry as Map<String, dynamic>),
    ];
  }

  /// Deletes every saved list's items. Used on sign-out.
  Future<void> clear() => _db.delete(_db.cachedListItems).go();
}

/// Supplies the [CachedItemsStore], backed by [appDatabaseProvider].
@Riverpod(keepAlive: true)
CachedItemsStore cachedItemsStore(Ref ref) =>
    CachedItemsStore(ref.watch(appDatabaseProvider));
