import 'dart:convert';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/sync/data/sources/cache/shopping_list_cache_payload.dart';
import 'package:freshcart_flutter/features/sync/data/sources/database/app_database.dart';

/// Persists the last-known state of the lists a user belongs to, so
/// `ListRepositoryImpl.myLists` and `ListRealtimeSource.watch` have
/// something to show when the very first fetch fails offline
/// (`docs/offline-sync-plan.md` §4's "cached reads").
///
/// A cache miss (`null`) and a confirmed-empty cache are not distinguished
/// here -- both read back as "nothing to show". The one place that matters
/// in practice is a brand-new account that has never once been online long
/// enough to sync: it sees the same "can't load, you're offline" state a
/// genuine cache miss would show, rather than an honestly-empty list.
/// Accepted rather than solved with a second "has synced" marker -- the
/// case requires being offline before ever completing a single successful
/// sync, which for a signed-in user is vanishingly rare next to the
/// ongoing cost of tracking it separately.
class CachedListsStore {
  const CachedListsStore(this._db);

  final AppDatabase _db;

  /// Upserts one list's snapshot -- used by `ListRealtimeSource.watch`'s
  /// write-through, which only ever knows about the one list it's watching.
  Future<void> upsert(ShoppingList list) => _db
      .into(_db.cachedLists)
      .insertOnConflictUpdate(
        CachedListsCompanion.insert(
          listId: list.id.value,
          data: jsonEncode(list.toCachePayload()),
          cachedAt: DateTime.now(),
        ),
      );

  /// Replaces the whole cached set with [lists] -- used by `myLists()`,
  /// which always returns the complete, authoritative set for this user.
  Future<void> replaceAll(List<ShoppingList> lists) =>
      _db.transaction(() async {
        await _db.delete(_db.cachedLists).go();
        for (final list in lists) {
          await upsert(list);
        }
      });

  /// The cached snapshot of one list, or `null` if it was never cached.
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

  /// Every cached list, or `null` if nothing has ever been cached.
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
