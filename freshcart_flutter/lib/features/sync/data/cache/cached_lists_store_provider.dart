import 'package:freshcart_flutter/features/sync/data/cache/cached_lists_store.dart';
import 'package:freshcart_flutter/features/sync/data/database/app_database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cached_lists_store_provider.g.dart';

/// Supplies the [CachedListsStore], backed by [appDatabaseProvider].
@Riverpod(keepAlive: true)
CachedListsStore cachedListsStore(Ref ref) =>
    CachedListsStore(ref.watch(appDatabaseProvider));
