import 'dart:async';

import 'package:freshcart_flutter/core/offline/queue/pending_operations_queue.dart';
import 'package:freshcart_flutter/core/offline/replay/pending_operations_replayer.dart';
import 'package:freshcart_flutter/core/offline/status/offline_status_providers.dart';
import 'package:freshcart_flutter/core/offline/status/sync_conflicts_controller.dart';
import 'package:freshcart_flutter/features/auth/application/auth/auth_providers.dart';
import 'package:freshcart_flutter/features/items/data/repositories/remote_item_repository.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/remote_list_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'offline_replay_providers.g.dart';

/// Supplies the [PendingOperationsReplayer], which sends saved changes to the server.
@Riverpod(keepAlive: true)
PendingOperationsReplayer pendingOperationsReplayer(Ref ref) =>
    PendingOperationsReplayer(
      ref.watch(pendingOperationsQueueProvider),
      ref.watch(remoteItemRepositoryProvider),
      ref.watch(remoteListRepositoryProvider),
    );

/// Sends saved offline changes to the server when we become online.
///
/// Returns nothing. It only has to exist, so `app.dart` watches it once to
/// start it.
@Riverpod(keepAlive: true)
void replayQueueWhenOnline(Ref ref) {
  // True while a replay is running. Two replays at once would both read the
  // same queue and send the same changes twice (duplicate items).
  var replaying = false;

  Future<void> replayOnce() async {
    if (replaying) return;
    replaying = true;
    try {
      // At app start we can be online before sign-in is done. Replaying
      // then would fail with "unauthorized", so wait for it.
      final signIn = await ref.read(signInResultProvider.future);
      if (!signIn.isOk) return;
      // Changes the server turned down (someone changed the same thing
      // first) are dropped from the queue; tell the user.
      final conflicted = await ref
          .read(pendingOperationsReplayerProvider)
          .replayAll();
      ref.read(syncConflictsControllerProvider.notifier).add(conflicted.length);
    } finally {
      replaying = false;
    }
  }

  ref.listen(connectivityStatusProvider, (previous, next) {
    // Replay when we BECOME online: coming back from offline, but also the
    // first status at app start (then `previous` is still loading, not
    // offline). Staying online (online -> online) doesn't replay again.
    final wasOnline = previous?.value == ConnectivityStatus.online;
    if (!wasOnline && next.value == ConnectivityStatus.online) {
      unawaited(replayOnce());
    }
  });
}
