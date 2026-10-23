import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/offline/cache/cached_lists_store.dart';
import 'package:freshcart_flutter/core/offline/connectivity/connectivity_adapter.dart';
import 'package:freshcart_flutter/core/offline/database/app_database.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_entity_type.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_op_type.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_operations_queue.dart';
import 'package:freshcart_flutter/features/lists/data/mappers/shopping_list_mapper.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/offline_list_repository.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/remote_list_repository.dart';

import '../../../../fakes/dto_builders.dart';
import '../../../../fakes/fake_client.dart';
import '../../../../fakes/fake_connectivity_adapter.dart';

void main() {
  late FakeClient client;
  late AppDatabase db;
  late CachedListsStore cache;
  late ListRepository repository;

  setUp(() {
    client = FakeClient();
    db = AppDatabase(NativeDatabase.memory());
    cache = CachedListsStore(db);
    repository = offlineOverRemote(
      client,
      PendingOperationsQueue(db),
      FakeConnectivityAdapter(const Stream.empty()),
      () => UserId(userUuid.uuid),
      cache,
    );
  });

  tearDown(() => db.close());

  group('offline over remote: success paths', () {
    test('myLists returns domain entities, never DTOs', () {
      client.handler = (_, _, _) => [buildListDto()];

      return repository.myLists().then((result) {
        expect(result.valueOrNull, isA<List<ShoppingList>>());
        expect(result.valueOrNull?.single.name, 'Groceries');
      });
    });

    test('create sends the name and returns the new list', () async {
      client.handler = (_, _, _) => buildListDto(name: 'Weekend');

      final result = await repository.create(name: 'Weekend');

      expect(result.valueOrNull?.name, 'Weekend');
      expect(client.calls.single.endpoint, 'list');
      expect(client.calls.single.method, 'create');
      expect(client.calls.single.args['name'], 'Weekend');
    });

    test('joinByCode sends the validated code string', () async {
      client.handler = (_, _, _) => buildListDto();
      final code = JoinCode.parse('ABC23').valueOrNull!;

      await repository.joinByCode(code);

      expect(client.calls.single.method, 'join');
      expect(client.calls.single.args['joinCode'], 'ABC23');
    });

    test('byId sends the id as a UUID', () async {
      client.handler = (_, _, _) => buildListDto();

      await repository.byId(ListId(listUuid.uuid));

      expect(client.calls.single.args['listId'], listUuid);
    });
  });

  group('offline over remote: failure translation', () {
    test('a server exception becomes an Err, not a throw', () async {
      client.handler = (_, _, _) => throw dto.NotAMemberException();

      final result = await repository.byId(ListId(listUuid.uuid));

      expect(result, const Err<ShoppingList>(Failure.unauthorized()));
    });

    test('a missing list becomes notFound', () async {
      client.handler = (_, _, _) => throw dto.ListNotFoundException();

      expect(
        (await repository.byId(ListId(listUuid.uuid))).failureOrNull,
        const Failure.notFound(),
      );
    });

    test('a server error (500) is unexpected, not a network problem', () async {
      client.handler = (_, _, _) =>
          throw dto.ServerpodClientInternalServerError();

      expect(
        (await repository.myLists()).failureOrNull,
        isA<UnexpectedFailure>(),
      );
    });

    test('a broken server contract surfaces as unexpected', () async {
      // A list with a malformed join code makes the mapper throw StateError.
      client.handler = (_, _, _) => buildListDto(joinCode: 'bad');

      expect(
        (await repository.myLists()).failureOrNull,
        isA<UnexpectedFailure>(),
      );
    });
  });

  group('offline over remote: real-time', () {
    test('watch seeds with the current list', () async {
      // Only the seed is exercised here — .first cancels the subscription as
      // soon as it arrives, before the source ever reaches the streaming
      // watchList call, so no streamHandler is needed for this one.
      client.handler = (_, _, _) => buildListDto();

      final first = await repository.watch(ListId(listUuid.uuid)).first;

      expect(first.valueOrNull?.name, 'Groceries');
    });

    test('watch follows renames and membership changes live', () async {
      // Streaming methods are a distinct transport path in a real Serverpod
      // client (a WebSocket, not an HTTP call), so FakeClient answers them
      // through streamHandler rather than handler.
      final updates = StreamController<dto.ShoppingList>();
      client.handler = (_, _, _) => buildListDto();
      client.streamHandler = (_, _, _) => updates.stream;

      final events = <Result<ShoppingList>>[];
      final subscription = repository
          .watch(ListId(listUuid.uuid))
          .listen(events.add);

      // Teardown order matters here and is easy to get backwards: cancelling
      // the *outer* subscription while it is suspended awaiting the *inner*
      // (`updates`) stream does not unwind that inner await, so an awaited
      // `subscription.cancel()` would deadlock forever waiting for a cancel
      // that can only complete once `updates` itself is done. Closing the
      // source first lets the generator finish naturally; cancelling the
      // already-finished subscription after that is then a no-op. (In the
      // real app this never bites: Riverpod's `ref.onDispose` never awaits its
      // callback, so `ref.onDispose(subscription.cancel)` fires-and-forgets
      // the very same call that would deadlock here if awaited.)
      addTearDown(subscription.cancel);
      addTearDown(updates.close);

      await Future<void>.delayed(Duration.zero);

      updates.add(buildListDto(name: 'Weekend shop'));
      await Future<void>.delayed(Duration.zero);

      expect(events.last.valueOrNull?.name, 'Weekend shop');
      expect(client.streamCalls.single.method, 'watchList');
    });

    test(
      'watch reports a failed seed instead of closing empty',
      () async {
        client.handler = (_, _, _) => throw dto.NotAMemberException();

        final first = await repository.watch(ListId(listUuid.uuid)).first;

        expect(first.failureOrNull, const Failure.unauthorized());
      },
    );
  });

  group('offline over remote: — offline retry/queue (Phase C)', () {
    test(
      'a single transient failure retries and succeeds, without queuing',
      () async {
        var attempt = 0;
        client.handler = (_, _, _) {
          attempt++;
          if (attempt == 1) {
            throw const dto.ServerpodClientException('down', -1);
          }
          return buildListDto(name: 'Weekend');
        };

        final result = await repository.create(name: 'Weekend');

        expect(client.calls, hasLength(2));
        expect(result.valueOrNull?.pending, isFalse);

        final queued = await db.select(db.pendingOperations).get();
        expect(queued, isEmpty);
      },
    );

    test(
      'sustained un-reachability queues the write and returns a pending Ok '
      'once retries are exhausted',
      () async {
        client.handler = (_, _, _) =>
            throw const dto.ServerpodClientException('down', -1);

        final result = await repository.create(name: 'Weekend');

        // maxAttempts: 2 in retryOnUnreachable — both calls fail before
        // _guard falls through to onUnreachable.
        expect(client.calls, hasLength(2));
        expect(result.isOk, isTrue);
        expect(result.valueOrNull?.pending, isTrue);

        final queued = await db.select(db.pendingOperations).get();
        expect(queued, hasLength(1));
        expect(queued.single.entityType, PendingEntityType.list);
        expect(queued.single.opType, PendingOpType.create);
      },
    );
  });

  group('offline over remote: — cached reads (Phase G)', () {
    test('myLists writes the result through to the cache', () async {
      client.handler = (_, _, _) => [buildListDto()];

      await repository.myLists();

      final cached = await cache.readAll();
      expect(cached, hasLength(1));
      expect(cached!.single.name, 'Groceries');
    });

    test(
      'myLists falls back to the cache when the server is unreachable',
      () async {
        await cache.replaceAll([
          buildListDto(name: 'Cached list').toDomain(),
        ]);
        client.handler = (_, _, _) =>
            throw const dto.ServerpodClientException('down', -1);

        final result = await repository.myLists();

        expect(result.valueOrNull?.single.name, 'Cached list');
      },
    );

    test(
      'myLists surfaces a non-network failure as-is, never falling back '
      'to the cache',
      () async {
        await cache.replaceAll([
          buildListDto(name: 'Cached list').toDomain(),
        ]);
        client.handler = (_, _, _) => throw dto.NotAMemberException();

        final result = await repository.myLists();

        expect(result.failureOrNull, const Failure.unauthorized());
      },
    );
  });

  group('offline over remote: real-time — reconnect (Phase F)', () {
    test(
      'a WebSocketClosedException mid-stream keeps the last good list and '
      'only re-fetches once reconnected',
      () async {
        final onlineController = StreamController<bool>.broadcast();
        final repo = offlineOverRemote(
          client,
          PendingOperationsQueue(db),
          FakeConnectivityAdapter(onlineController.stream),
          () => UserId(userUuid.uuid),
          cache,
        );

        var byIdCallCount = 0;
        client.handler = (_, _, _) {
          byIdCallCount++;
          return buildListDto(
            name: byIdCallCount == 1 ? 'Groceries' : 'Weekend shop',
          );
        };
        final updateControllers = <StreamController<dto.ShoppingList>>[];
        client.streamHandler = (_, _, _) {
          final controller = StreamController<dto.ShoppingList>();
          updateControllers.add(controller);
          return controller.stream;
        };

        final events = <Result<ShoppingList>>[];
        final subscription = repo
            .watch(ListId(listUuid.uuid))
            .listen(events.add);

        // Same ordering lesson as the plain watch test above: close the
        // source before cancelling the outer subscription, or an awaited
        // cancel() can deadlock waiting for a generator that only wakes up
        // in response to its own source.
        addTearDown(subscription.cancel);
        addTearDown(() async {
          for (final c in updateControllers) {
            await c.close();
          }
        });
        addTearDown(onlineController.close);

        await Future<void>.delayed(Duration.zero);
        expect(byIdCallCount, 1);
        expect(events.single.valueOrNull?.name, 'Groceries');

        // The live socket dies -- no Err should reach the listener, and the
        // last good list must stay exactly as it was.
        updateControllers.single.addError(const dto.WebSocketClosedException());
        await Future<void>.delayed(Duration.zero);
        expect(events, hasLength(1));

        // Still offline: no re-fetch has happened yet.
        expect(byIdCallCount, 1);

        // Reconnect.
        onlineController.add(true);
        await Future<void>.delayed(Duration.zero);

        expect(byIdCallCount, 2); // a fresh full snapshot, not a resume
        expect(events.last.valueOrNull?.name, 'Weekend shop');
        expect(updateControllers, hasLength(2)); // resubscribed
      },
    );

    test(
      'a NotAMemberException mid-stream still ends with one Err, not '
      'treated as recoverable',
      () async {
        final repo = offlineOverRemote(
          client,
          PendingOperationsQueue(db),
          FakeConnectivityAdapter(const Stream.empty()),
          () => UserId(userUuid.uuid),
          cache,
        );

        client.handler = (_, _, _) => buildListDto();
        final updateController = StreamController<dto.ShoppingList>();
        client.streamHandler = (_, _, _) => updateController.stream;

        final events = <Result<ShoppingList>>[];
        final subscription = repo
            .watch(ListId(listUuid.uuid))
            .listen(events.add);
        addTearDown(subscription.cancel);
        addTearDown(updateController.close);

        await Future<void>.delayed(Duration.zero);
        updateController.addError(dto.NotAMemberException());
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(2)); // seed Ok, then one Err
        expect(events.last.failureOrNull, const Failure.unauthorized());
      },
    );
  });
}

/// The list repository the app uses: [OfflineListRepository] over
/// [RemoteListRepository], wired like `listRepositoryProvider`.
ListRepository offlineOverRemote(
  dto.Client client,
  PendingOperationsQueue queue,
  ConnectivityAdapter connectivity,
  UserId Function() me,
  CachedListsStore cache,
) => OfflineListRepository(
  RemoteListRepository(client, connectivity, cache),
  queue,
  cache,
  me,
);
