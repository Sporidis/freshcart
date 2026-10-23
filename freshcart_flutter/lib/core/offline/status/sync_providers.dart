import 'dart:async';

import 'package:freshcart_flutter/core/offline/connectivity/connectivity_adapter.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_operations_queue.dart';
import 'package:freshcart_flutter/core/offline/status/sync_banner.dart';
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
