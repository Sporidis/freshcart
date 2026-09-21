import 'package:freshcart_flutter/features/sync/application/sync_status.dart';
import 'package:freshcart_flutter/features/sync/data/connectivity_adapter_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_provider.g.dart';

/// The device's live [SyncStatus], driven by [connectivityAdapterProvider].
@Riverpod(keepAlive: true)
Stream<SyncStatus> sync(Ref ref) => ref
    .watch(connectivityAdapterProvider)
    .watchIsOnline()
    .map((isOnline) => isOnline ? SyncStatus.online : SyncStatus.offline);
