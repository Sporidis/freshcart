import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_flutter/features/sync/application/sync/sync_banner.dart';
import 'package:freshcart_flutter/features/sync/application/sync/sync_providers.dart';

void main() {
  /// [syncBannerProvider] once both of its streams have delivered.
  Future<SyncBanner> banner({SyncStatus? status, int pending = 0}) async {
    final container = ProviderContainer(
      overrides: [
        syncProvider.overrideWith(
          (ref) => status == null ? const Stream.empty() : Stream.value(status),
        ),
        pendingWriteCountProvider.overrideWith((ref) => Stream.value(pending)),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(syncBannerProvider, (_, _) {});
    addTearDown(sub.close);
    await pumpEventQueue();
    return container.read(syncBannerProvider);
  }

  test('offline says offline, with how many changes are waiting', () async {
    final none = await banner(status: SyncStatus.offline);
    expect(none, isA<SyncBannerOffline>());
    expect((none as SyncBannerOffline).pending, 0);

    final three = await banner(status: SyncStatus.offline, pending: 3);
    expect((three as SyncBannerOffline).pending, 3);
  });

  test('online with writes still queued says how many are syncing', () async {
    final result = await banner(status: SyncStatus.online, pending: 3);
    expect(result, isA<SyncBannerSyncing>());
    expect((result as SyncBannerSyncing).pending, 3);
  });

  test('online with nothing queued shows nothing', () async {
    expect(await banner(status: SyncStatus.online), isA<SyncBannerHidden>());
  });

  test('an unknown connection shows nothing rather than guessing', () async {
    expect(await banner(pending: 3), isA<SyncBannerHidden>());
  });
}
