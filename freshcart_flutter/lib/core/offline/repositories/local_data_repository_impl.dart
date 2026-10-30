import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/offline/cache/cached_items_store.dart';
import 'package:freshcart_flutter/core/offline/cache/cached_lists_store.dart';
import 'package:freshcart_flutter/core/offline/database/app_database.dart';
import 'package:freshcart_flutter/core/offline/database/app_database_provider.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_operations_queue.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'local_data_repository_impl.g.dart';

/// The [LocalDataRepository] on this device's drift database.
///
/// Only coordinates: each table is cleared by the class that owns it (the
/// queue and the two caches), so each of them stays the only one touching
/// its table. All three are cleared in one transaction: drift transactions
/// follow the call, so the owners' deletes join it, and sign-out never
/// leaves half a user's data behind.
class LocalDataRepositoryImpl implements LocalDataRepository {
  const LocalDataRepositoryImpl(
    this._db,
    this._queue,
    this._lists,
    this._items,
  );

  final AppDatabase _db;
  final PendingOperationsQueue _queue;
  final CachedListsStore _lists;
  final CachedItemsStore _items;

  /// Deletes the queue and both caches, all or nothing.
  @override
  Future<void> clear() async {
    await _db.transaction(() async {
      await _queue.clear();
      await _lists.clear();
      await _items.clear();
    });
  }

  @override
  Future<int> pendingChangeCount() => _queue.count();
}

/// Supplies the app's [LocalDataRepository].
///
/// Its type is the interface, so the rest of the app only knows the port,
/// and tests can swap in a fake.
@Riverpod(keepAlive: true)
LocalDataRepository localDataRepository(Ref ref) => LocalDataRepositoryImpl(
  ref.watch(appDatabaseProvider),
  ref.watch(pendingOperationsQueueProvider),
  ref.watch(cachedListsStoreProvider),
  ref.watch(cachedItemsStoreProvider),
);
