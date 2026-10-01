import 'package:freshcart_flutter/features/items/data/repositories/item_repository_impl.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/list_repository_impl.dart';
import 'package:freshcart_flutter/features/sync/application/sync/sync_banner.dart';

import 'package:freshcart_flutter/features/sync/data/sources/connectivity/connectivity_adapter.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/pending_operations_queue.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/queue_drainer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_providers.g.dart';

/// The device's connectivity state, as observed by `features/sync`.
enum SyncStatus {
  /// The device has a network interface up.
  online,

  /// The device has no network interface up.
  offline,
}

/// The device's live [SyncStatus], driven by [connectivityAdapterProvider].
@Riverpod(keepAlive: true)
Stream<SyncStatus> sync(Ref ref) => ref
    .watch(connectivityAdapterProvider)
    .watchIsOnline()
    .map((isOnline) => isOnline ? SyncStatus.online : SyncStatus.offline);

/// How many offline writes are still waiting to reach the server.
@Riverpod(keepAlive: true)
Stream<int> pendingWriteCount(Ref ref) =>
    ref.watch(pendingOperationsQueueProvider).watchCount();

/// What the banner above the list should show. "Syncing" needs both
/// sources at once -- online *and* writes still queued -- which is exactly
/// the combining a widget must not do itself.
@riverpod
SyncBanner syncBanner(Ref ref) {
  final status = ref.watch(syncProvider).value;
  final pending = ref.watch(pendingWriteCountProvider).value ?? 0;
  return switch (status) {
    SyncStatus.offline => const SyncBannerOffline(),
    SyncStatus.online when pending > 0 => SyncBannerSyncing(pending),
    _ => const SyncBannerHidden(),
  };
}

@Riverpod(keepAlive: true)
QueueDrainer queueDrainer(Ref ref) => QueueDrainer(
  ref.watch(pendingOperationsQueueProvider),
  ref.watch(itemRepositoryProvider),
  ref.watch(listRepositoryProvider),
);

@Riverpod(keepAlive: true)
void queueDrainCoordinator(Ref ref) {
  ref.listen(syncProvider, (previous, next) async {
    if (previous?.value == SyncStatus.offline &&
        next.value == SyncStatus.online) {
      await ref.read(queueDrainerProvider).drain();
    }
  });
}
