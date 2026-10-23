import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_flutter/core/offline/status/offline_status_providers.dart';
import 'package:freshcart_flutter/core/offline/status/sync_banner_state.dart';

void main() {
  /// [syncBannerStateProvider] once both of its streams have delivered.
  Future<SyncBannerState> banner({
    ConnectivityStatus? status,
    int pending = 0,
  }) async {
    final container = ProviderContainer(
      overrides: [
        connectivityStatusProvider.overrideWith(
          (ref) => status == null ? const Stream.empty() : Stream.value(status),
        ),
        pendingWriteCountProvider.overrideWith((ref) => Stream.value(pending)),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(syncBannerStateProvider, (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    return container.read(syncBannerStateProvider);
  }

  test('offline says offline, with how many changes are waiting', () async {
    final none = await banner(status: ConnectivityStatus.offline);
    expect(none, isA<SyncBannerOffline>());
    expect((none as SyncBannerOffline).pending, 0);

    final three = await banner(status: ConnectivityStatus.offline, pending: 3);
    expect((three as SyncBannerOffline).pending, 3);
  });

  test('online with writes still queued says how many are syncing', () async {
    final result = await banner(status: ConnectivityStatus.online, pending: 3);
    expect(result, isA<SyncBannerSyncing>());
    expect((result as SyncBannerSyncing).pending, 3);
  });

  test('online with nothing queued shows nothing', () async {
    expect(
      await banner(status: ConnectivityStatus.online),
      isA<SyncBannerHidden>(),
    );
  });

  test('an unknown connection shows nothing rather than guessing', () async {
    expect(await banner(pending: 3), isA<SyncBannerHidden>());
  });
}
