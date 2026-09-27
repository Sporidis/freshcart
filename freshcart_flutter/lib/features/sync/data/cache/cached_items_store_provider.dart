import 'package:freshcart_flutter/features/sync/data/cache/cached_items_store.dart';
import 'package:freshcart_flutter/features/sync/data/database/app_database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cached_items_store_provider.g.dart';

/// Supplies the [CachedItemsStore], backed by [appDatabaseProvider].
@Riverpod(keepAlive: true)
CachedItemsStore cachedItemsStore(Ref ref) =>
    CachedItemsStore(ref.watch(appDatabaseProvider));
