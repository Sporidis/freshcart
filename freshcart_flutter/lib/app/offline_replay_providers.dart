import 'dart:async';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_operations_queue.dart';
import 'package:freshcart_flutter/core/offline/replay/pending_operations_replayer.dart';
import 'package:freshcart_flutter/core/offline/status/offline_status_providers.dart';
import 'package:freshcart_flutter/core/offline/status/replay_activity_controller.dart';
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

/// How long to wait before trying again to send changes that are still
/// waiting while online. A provider so tests can make it short.
@Riverpod(keepAlive: true)
Duration replayRetryInterval(Ref ref) => const Duration(seconds: 30);

/// Sends saved offline changes to the server when we become online.
///
/// Returns nothing. It only has to exist, so `app.dart` watches it once to
/// start it.
@Riverpod(keepAlive: true)
void replayQueueWhenOnline(Ref ref) {
  // True while a replay is running. Two replays at once would both read the
  // same queue and send the same changes twice (duplicate items).
  bool replaying = false;

  Future<void> replayOnce() async {
    if (replaying) return;
    replaying = true;
    try {
      // A start without the server leaves sign-in failed, and nothing else
      // retries it. Back online is the moment it can work.
      if (signInFailed(ref.read(signInResultProvider))) {
        ref.invalidate(signInResultProvider);
      }
      // At app start we can be online before sign-in is done. Replaying
      // then would fail with "unauthorized", so wait for it.
      final signIn = await ref.read(signInResultProvider.future);
      if (!signIn.isOk) return;
      // Changes the server turned down (someone changed the same thing
      // first) are dropped from the queue; tell the user.
      final activity = ref.read(replayActivityControllerProvider.notifier)
        ..started();
      try {
        final conflicted = await ref
            .read(pendingOperationsReplayerProvider)
            .replayAll();
        ref
            .read(syncConflictsControllerProvider.notifier)
            .add(conflicted.length);
      } finally {
        // Also when the server couldn't be reached halfway: the banner
        // must not keep saying "Syncing".
        activity.finished();
      }
    } finally {
      replaying = false;
    }
  }

  // A sign-in that worked after failing (retried on coming back to the
  // app, while the network never dropped) also means: send the queue now.
  ref.listen(signInResultProvider, (previous, next) {
    final failedBefore = previous?.value?.isOk == false;
    final signedInNow = switch (next) {
      AsyncData(value: Ok(), isLoading: false) => true,
      _ => false,
    };
    if (failedBefore && signedInNow) unawaited(replayOnce());
  });

  // Online with changes still waiting, and nothing else will try again:
  // the server came back while the network never dropped, or it failed
  // halfway. Retry now and then, but only while there is something to
  // send, so an empty queue keeps no timer running.
  Timer? retry;
  void scheduleRetry() {
    retry?.cancel();
    retry = null;
    final online =
        ref.read(connectivityStatusProvider).value == ConnectivityStatus.online;
    final waiting = ref.read(pendingWriteCountProvider).value ?? 0;
    if (!online || waiting == 0) return;
    retry = Timer(ref.read(replayRetryIntervalProvider), () {
      unawaited(replayOnce().whenComplete(scheduleRetry));
    });
  }

  ref
    ..onDispose(() => retry?.cancel())
    ..listen(pendingWriteCountProvider, (_, _) => scheduleRetry());

  ref.listen(connectivityStatusProvider, (previous, next) {
    // Replay only on the switch to online, from anything that isn't online:
    // offline, or still loading at app start. Staying online doesn't
    // replay again.
    final wasOnline = previous?.value == ConnectivityStatus.online;
    if (!wasOnline && next.value == ConnectivityStatus.online) {
      unawaited(replayOnce());
    }
    scheduleRetry();
  });
}
