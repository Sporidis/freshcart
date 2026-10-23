import 'dart:async';

import 'package:freshcart_flutter/core/offline/connectivity/connectivity_adapter.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_operations_queue.dart';
import 'package:freshcart_flutter/core/offline/status/sync_banner_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'offline_status_providers.g.dart';

/// Whether the phone has a network connection.
///
/// Note: "online" only means Wi-Fi or mobile data is on. The server could
/// still be unreachable.
enum ConnectivityStatus {
  /// Wi-Fi or mobile data is connected.
  online,

  /// No network at all.
  offline,
}

/// The current [ConnectivityStatus], updated every time it changes.
@Riverpod(keepAlive: true)
Stream<ConnectivityStatus> connectivityStatus(Ref ref) => ref
    .watch(connectivityAdapterProvider)
    .watchIsOnline()
    .map(
      (isOnline) =>
          isOnline ? ConnectivityStatus.online : ConnectivityStatus.offline,
    );

/// How many changes made offline are still waiting to be sent.
@Riverpod(keepAlive: true)
Stream<int> pendingWriteCount(Ref ref) =>
    ref.watch(pendingOperationsQueueProvider).watchCount();

/// Which banner to show above the list.
///
/// Combines two providers (online status and waiting changes), so the
/// widget doesn't have to.
@riverpod
SyncBannerState syncBannerState(Ref ref) {
  final status = ref.watch(connectivityStatusProvider).value;
  final pending = ref.watch(pendingWriteCountProvider).value ?? 0;
  return switch (status) {
    ConnectivityStatus.offline => SyncBannerOffline(pending),
    ConnectivityStatus.online when pending > 0 => SyncBannerSyncing(pending),
    _ => const SyncBannerHidden(),
  };
}
