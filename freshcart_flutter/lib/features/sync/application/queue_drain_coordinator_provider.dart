import 'package:freshcart_flutter/features/sync/application/queue_drainer_provider.dart';
import 'package:freshcart_flutter/features/sync/application/sync_provider.dart';
import 'package:freshcart_flutter/features/sync/application/sync_status.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'queue_drain_coordinator_provider.g.dart';

@Riverpod(keepAlive: true)
void queueDrainCoordinator(Ref ref) {
  ref.listen(syncProvider, (previous, next) async {
    if (previous?.value == SyncStatus.offline &&
        next.value == SyncStatus.online) {
      await ref.read(queueDrainerProvider).drain();
    }
  });
}
