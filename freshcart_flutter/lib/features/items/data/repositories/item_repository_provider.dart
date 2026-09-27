import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/di/serverpod_client_provider.dart';
import 'package:freshcart_flutter/features/auth/data/sources/current_user_provider.dart';
import 'package:freshcart_flutter/features/items/data/repositories/item_repository_impl.dart';
import 'package:freshcart_flutter/features/sync/data/sources/cache/cached_items_store_provider.dart';
import 'package:freshcart_flutter/features/sync/data/sources/connectivity/connectivity_adapter_provider.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/pending_operations_queue_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'item_repository_provider.g.dart';

/// Supplies the [ItemRepository] port.
@Riverpod(keepAlive: true)
ItemRepository itemRepository(Ref ref) => ItemRepositoryImpl(
  ref.watch(serverpodClientProvider),
  ref.watch(pendingOperationsQueueProvider),
  ref.watch(connectivityAdapterProvider),
  () =>
      ref.read(currentUserIdProvider).asData?.value.valueOrNull ??
      (throw StateError(
        'currentUserId not resolved — cannot queue an offline add without a known user',
      )),
  ref.watch(cachedItemsStoreProvider),
);
