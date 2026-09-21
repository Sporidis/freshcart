import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/di/serverpod_client_provider.dart';
import 'package:freshcart_flutter/features/auth/data/current_user_provider.dart';
import 'package:freshcart_flutter/features/lists/data/list_repository_impl.dart';
import 'package:freshcart_flutter/features/sync/data/cached_lists_store_provider.dart';
import 'package:freshcart_flutter/features/sync/data/connectivity_adapter_provider.dart';
import 'package:freshcart_flutter/features/sync/data/pending_operations_queue_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'list_repository_provider.g.dart';

/// Supplies the [ListRepository] port.
///
/// The provider's type is the *domain port*, not the implementation, so
/// everything above it depends on the interface and a test can override this
/// with a fake without the app noticing.
@Riverpod(keepAlive: true)
ListRepository listRepository(Ref ref) => ListRepositoryImpl(
  ref.watch(serverpodClientProvider),
  ref.watch(pendingOperationsQueueProvider),
  ref.watch(connectivityAdapterProvider),
  () =>
      ref.read(currentUserIdProvider).asData?.value.valueOrNull ??
      (throw StateError(
        'currentUserId not resolved — cannot queue an offline add without a known user',
      )),
  ref.watch(cachedListsStoreProvider),
);
