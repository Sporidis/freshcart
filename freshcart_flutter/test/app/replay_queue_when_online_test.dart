import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app/offline_replay_providers.dart';
import 'package:freshcart_flutter/core/offline/database/app_database.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_entity_type.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_op_type.dart';
import 'package:freshcart_flutter/core/offline/replay/pending_operations_replayer.dart';
import 'package:freshcart_flutter/core/offline/status/offline_status_providers.dart';
import 'package:freshcart_flutter/core/offline/status/sync_conflicts_controller.dart';
import 'package:freshcart_flutter/features/auth/application/auth/auth_providers.dart';

import '../fakes/fake_auth_repository.dart';

/// Counts how often [replayAll] is called. Set [gate] to keep a replay "running"
/// until the test completes it.
class _FakeReplayer implements PendingOperationsReplayer {
  int calls = 0;
  Completer<void>? gate;

  /// What [replayAll] reports as turned down by the server.
  List<PendingOperation> conflicted = const [];

  @override
  Future<List<PendingOperation>> replayAll() async {
    calls++;
    await gate?.future;
    return conflicted;
  }
}

void main() {
  late StreamController<ConnectivityStatus> status;
  late _FakeReplayer replayer;

  /// How many times sign-in ran.
  late int signIns;

  /// Starts the coordinator with a fake connection and replayer. Sign-in
  /// fails the first [failingSignIns] times, then works.
  ProviderContainer start({bool signedIn = true, int failingSignIns = 0}) {
    signIns = 0;
    status = StreamController<ConnectivityStatus>();
    replayer = _FakeReplayer();
    final container = ProviderContainer(
      overrides: [
        connectivityStatusProvider.overrideWith((ref) => status.stream),
        pendingOperationsReplayerProvider.overrideWithValue(replayer),
        signInResultProvider.overrideWith((ref) async {
          signIns++;
          final works = signedIn && signIns > failingSignIns;
          return works ? Ok(aSignIn()) : const Err(Failure.network());
        }),
      ],
    );
    addTearDown(container.dispose);
    // Not awaited: close() only completes once the stream was listened to.
    addTearDown(() => unawaited(status.close()));
    // `listen`, not `read`: Riverpod 3 pauses providers nobody listens to,
    // and a paused coordinator wouldn't get the status changes. (In the app,
    // `app.dart` watches it.)
    final sub = container.listen(replayQueueWhenOnlineProvider, (_, _) {});
    addTearDown(sub.close);
    return container;
  }

  Future<void> emit(ConnectivityStatus value) async {
    status.add(value);
    await pumpEventQueue();
  }

  test('changes the server turned down are counted, for the toast', () async {
    final container = start();
    PendingOperation op(int id) => PendingOperation(
      id: id,
      entityType: PendingEntityType.item,
      opType: PendingOpType.edit,
      payload: '{}',
      queuedAt: DateTime.utc(2026, 10),
    );
    replayer.conflicted = [op(1), op(2)];

    await emit(ConnectivityStatus.online);

    expect(container.read(syncConflictsControllerProvider), 2);
  });

  test('a replay with nothing turned down counts nothing', () async {
    final container = start();
    await emit(ConnectivityStatus.online);
    expect(container.read(syncConflictsControllerProvider), 0);
  });

  test('replays when the app starts already online', () async {
    start();
    await emit(ConnectivityStatus.online);
    expect(replayer.calls, 1);
  });

  test('replays when coming back online', () async {
    start();
    await emit(ConnectivityStatus.offline);
    await emit(ConnectivityStatus.online);
    expect(replayer.calls, 1);
  });

  test('does not replay while offline', () async {
    start();
    await emit(ConnectivityStatus.offline);
    expect(replayer.calls, 0);
  });

  test('does not replay again while staying online', () async {
    start();
    await emit(ConnectivityStatus.online);
    await emit(ConnectivityStatus.online);
    expect(replayer.calls, 1);
  });

  test('never runs two replays at the same time', () async {
    start();
    replayGate() => replayer.gate = Completer<void>();
    replayGate();
    await emit(ConnectivityStatus.online);
    // The network flickers while the first replay is still running.
    await emit(ConnectivityStatus.offline);
    await emit(ConnectivityStatus.online);
    expect(replayer.calls, 1);
    replayer.gate!.complete();
    await pumpEventQueue();
  });

  test('does not replay when sign-in failed', () async {
    start(signedIn: false);
    await emit(ConnectivityStatus.online);
    expect(replayer.calls, 0);
  });

  test('a sign-in that failed at start is retried on coming back online, '
      'and then the queue is sent', () async {
    final container = start(failingSignIns: 1);
    // The start: no server, so sign-in failed.
    await container.read(signInResultProvider.future);
    expect(signIns, 1);

    await emit(ConnectivityStatus.online);

    expect(signIns, 2);
    expect(replayer.calls, 1);
  });

  test('a sign-in that recovers some other way also sends the queue', () async {
    final container = start(failingSignIns: 1);
    await container.read(signInResultProvider.future);

    // E.g. retried on coming back to the app, the network never dropped.
    container.invalidate(signInResultProvider);
    await container.read(signInResultProvider.future);
    await pumpEventQueue();

    expect(replayer.calls, 1);
  });
}
