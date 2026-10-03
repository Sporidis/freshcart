import 'dart:convert';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/sync/data/sources/cache/shopping_list_cache_payload.dart';
import 'package:freshcart_flutter/features/sync/data/sources/database/app_database.dart';
import 'package:freshcart_flutter/features/sync/data/sources/database/app_database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cached_lists_store.g.dart';

/// Saves the user's lists on the phone, so they can still be shown when the
/// app opens without internet.
///
/// Known limitation: "never saved" and "saved, but the user has no lists"
/// both read back as `null`. So a brand-new user who is offline from the
/// start sees "you're offline" instead of an empty list. That's rare
/// enough that we accept it.
class CachedListsStore {
  const CachedListsStore(this._db);

  final AppDatabase _db;

  /// Saves one list, or updates it if it's already saved. Used when
  /// watching a single list.
  Future<void> upsert(ShoppingList list) => _db
      .into(_db.cachedLists)
      .insertOnConflictUpdate(
        CachedListsCompanion.insert(
          listId: list.id.value,
          data: jsonEncode(list.toCachePayload()),
          cachedAt: DateTime.now(),
        ),
      );

  /// Deletes all saved lists and saves [lists] instead. Used by `myLists()`,
  /// which always gets all of the user's lists from the server.
  Future<void> replaceAll(List<ShoppingList> lists) =>
      _db.transaction(() async {
        await _db.delete(_db.cachedLists).go();
        for (final list in lists) {
          await upsert(list);
        }
      });

  /// The saved version of one list, or `null` if it was never saved.
  Future<ShoppingList?> read(ListId id) async {
    final row = await (_db.select(
      _db.cachedLists,
    )..where((row) => row.listId.equals(id.value))).getSingleOrNull();
    return row == null
        ? null
        : shoppingListFromCachePayload(
            jsonDecode(row.data) as Map<String, dynamic>,
          );
  }

  /// All saved lists, or `null` if there are none.
  Future<List<ShoppingList>?> readAll() async {
    final rows = await _db.select(_db.cachedLists).get();
    if (rows.isEmpty) return null;
    return [
      for (final row in rows)
        shoppingListFromCachePayload(
          jsonDecode(row.data) as Map<String, dynamic>,
        ),
    ];
  }
}

/// Supplies the [CachedListsStore], backed by [appDatabaseProvider].
@Riverpod(keepAlive: true)
CachedListsStore cachedListsStore(Ref ref) =>
    CachedListsStore(ref.watch(appDatabaseProvider));
