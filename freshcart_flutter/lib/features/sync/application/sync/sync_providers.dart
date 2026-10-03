import 'dart:async';

import 'package:freshcart_flutter/features/auth/data/sources/anonymous_session_bootstrap.dart';
import 'package:freshcart_flutter/features/items/data/repositories/item_repository_impl.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/list_repository_impl.dart';
import 'package:freshcart_flutter/features/sync/application/sync/sync_banner.dart';

import 'package:freshcart_flutter/features/sync/data/sources/connectivity/connectivity_adapter.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/pending_operations_queue.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/queue_drainer.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_providers.g.dart';

/// Whether the phone has a network connection.
///
/// Note: "online" only means Wi-Fi or mobile data is on. The server could
/// still be unreachable.
enum SyncStatus {
  /// Wi-Fi or mobile data is connected.
  online,

  /// No network at all.
  offline,
}

/// The current [SyncStatus], updated every time it changes.
@Riverpod(keepAlive: true)
Stream<SyncStatus> sync(Ref ref) => ref
    .watch(connectivityAdapterProvider)
    .watchIsOnline()
    .map((isOnline) => isOnline ? SyncStatus.online : SyncStatus.offline);

/// How many changes made offline are still waiting to be sent.
@Riverpod(keepAlive: true)
Stream<int> pendingWriteCount(Ref ref) =>
    ref.watch(pendingOperationsQueueProvider).watchCount();

/// Which banner to show above the list.
///
/// Combines two providers (online status and waiting changes), so the
/// widget doesn't have to.
@riverpod
SyncBanner syncBanner(Ref ref) {
  final status = ref.watch(syncProvider).value;
  final pending = ref.watch(pendingWriteCountProvider).value ?? 0;
  return switch (status) {
    SyncStatus.offline => SyncBannerOffline(pending),
    SyncStatus.online when pending > 0 => SyncBannerSyncing(pending),
    _ => const SyncBannerHidden(),
  };
}

/// Supplies the [QueueDrainer], which sends saved changes to the server.
@Riverpod(keepAlive: true)
QueueDrainer queueDrainer(Ref ref) => QueueDrainer(
  ref.watch(pendingOperationsQueueProvider),
  ref.watch(itemRepositoryProvider),
  ref.watch(listRepositoryProvider),
);

/// Sends saved offline changes to the server when we become online.
///
/// Returns nothing. It only has to exist, so `app.dart` watches it once to
/// start it.
@Riverpod(keepAlive: true)
void queueDrainCoordinator(Ref ref) {
  // True while a drain is running. Two drains at once would both read the
  // same queue and send the same changes twice (duplicate items).
  var draining = false;

  Future<void> drainOnce() async {
    if (draining) return;
    draining = true;
    try {
      // At app start we can be online before sign-in is done. Draining
      // then would fail with "unauthorized", so wait for it.
      final session = await ref.read(authBootstrapProvider.future);
      if (!session.authenticated) return;
      await ref.read(queueDrainerProvider).drain();
    } finally {
      draining = false;
    }
  }

  ref.listen(syncProvider, (previous, next) {
    // Drain when we BECOME online: coming back from offline, but also the
    // first status at app start (then `previous` is still loading, not
    // offline). Staying online (online -> online) doesn't drain again.
    final wasOnline = previous?.value == SyncStatus.online;
    if (!wasOnline && next.value == SyncStatus.online) {
      unawaited(drainOnce());
    }
  });
}
