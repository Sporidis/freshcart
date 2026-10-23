import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_flutter/app/offline_replay_providers.dart';
import 'package:freshcart_flutter/core/offline/database/app_database.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_operations_table.dart';
import 'package:freshcart_flutter/core/offline/replay/queue_drainer.dart';
import 'package:freshcart_flutter/core/offline/status/sync_conflicts_controller.dart';
import 'package:freshcart_flutter/core/offline/status/sync_providers.dart';
import 'package:freshcart_flutter/features/auth/data/sources/anonymous_session_bootstrap.dart';

/// Counts how often [drain] is called. Set [gate] to keep a drain "running"
/// until the test completes it.
class _FakeDrainer implements QueueDrainer {
  int calls = 0;
  Completer<void>? gate;

  /// What [drain] reports as turned down by the server.
  List<PendingOperation> conflicted = const [];

  @override
  Future<List<PendingOperation>> drain() async {
    calls++;
    await gate?.future;
    return conflicted;
  }
}

void main() {
  late StreamController<SyncStatus> status;
  late _FakeDrainer drainer;

  /// Starts the coordinator with a fake connection and drainer.
  ProviderContainer start({bool signedIn = true}) {
    status = StreamController<SyncStatus>();
    drainer = _FakeDrainer();
    final container = ProviderContainer(
      overrides: [
        syncProvider.overrideWith((ref) => status.stream),
        queueDrainerProvider.overrideWithValue(drainer),
        authBootstrapProvider.overrideWith(
          (ref) async => (authenticated: signedIn, isNewIdentity: false),
        ),
      ],
    );
    addTearDown(container.dispose);
    // Not awaited: close() only completes once the stream was listened to.
    addTearDown(() => unawaited(status.close()));
    // `listen`, not `read`: Riverpod 3 pauses providers nobody listens to,
    // and a paused coordinator wouldn't get the status changes. (In the app,
    // `app.dart` watches it.)
    final sub = container.listen(queueDrainCoordinatorProvider, (_, _) {});
    addTearDown(sub.close);
    return container;
  }

  Future<void> emit(SyncStatus value) async {
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
    drainer.conflicted = [op(1), op(2)];

    await emit(SyncStatus.online);

    expect(container.read(syncConflictsControllerProvider), 2);
  });

  test('a drain with nothing turned down counts nothing', () async {
    final container = start();
    await emit(SyncStatus.online);
    expect(container.read(syncConflictsControllerProvider), 0);
  });

  test('drains when the app starts already online', () async {
    start();
    await emit(SyncStatus.online);
    expect(drainer.calls, 1);
  });

  test('drains when coming back online', () async {
    start();
    await emit(SyncStatus.offline);
    await emit(SyncStatus.online);
    expect(drainer.calls, 1);
  });

  test('does not drain while offline', () async {
    start();
    await emit(SyncStatus.offline);
    expect(drainer.calls, 0);
  });

  test('does not drain again while staying online', () async {
    start();
    await emit(SyncStatus.online);
    await emit(SyncStatus.online);
    expect(drainer.calls, 1);
  });

  test('never runs two drains at the same time', () async {
    start();
    drainerGate() => drainer.gate = Completer<void>();
    drainerGate();
    await emit(SyncStatus.online);
    // The network flickers while the first drain is still running.
    await emit(SyncStatus.offline);
    await emit(SyncStatus.online);
    expect(drainer.calls, 1);
    drainer.gate!.complete();
    await pumpEventQueue();
  });

  test('does not drain when sign-in failed', () async {
    start(signedIn: false);
    await emit(SyncStatus.online);
    expect(drainer.calls, 0);
  });
}
