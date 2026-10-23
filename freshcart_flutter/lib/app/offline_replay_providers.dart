import 'dart:async';

import 'package:freshcart_flutter/core/offline/queue/pending_operations_queue.dart';
import 'package:freshcart_flutter/core/offline/replay/queue_drainer.dart';
import 'package:freshcart_flutter/core/offline/status/sync_conflicts_controller.dart';
import 'package:freshcart_flutter/core/offline/status/sync_providers.dart';
import 'package:freshcart_flutter/features/auth/data/sources/anonymous_session_bootstrap.dart';
import 'package:freshcart_flutter/features/items/data/repositories/remote_item_repository.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/remote_list_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'offline_replay_providers.g.dart';

/// Supplies the [QueueDrainer], which sends saved changes to the server.
@Riverpod(keepAlive: true)
QueueDrainer queueDrainer(Ref ref) => QueueDrainer(
  ref.watch(pendingOperationsQueueProvider),
  ref.watch(remoteItemRepositoryProvider),
  ref.watch(remoteListRepositoryProvider),
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
      // Changes the server turned down (someone changed the same thing
      // first) are dropped from the queue; tell the user.
      final conflicted = await ref.read(queueDrainerProvider).drain();
      ref.read(syncConflictsControllerProvider.notifier).add(conflicted.length);
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
