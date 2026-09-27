import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/items/data/mappers/shopping_item_mapper.dart';
import 'package:freshcart_flutter/features/items/data/repositories/item_repository_impl.dart';
import 'package:freshcart_flutter/features/sync/data/sources/cache/cached_items_store.dart';
import 'package:freshcart_flutter/features/sync/data/sources/database/app_database.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/pending_operations_queue.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/pending_operations_table.dart';

import '../../../../fakes/dto_builders.dart';
import '../../../../fakes/fake_client.dart';
import '../../../../fakes/fake_connectivity_adapter.dart';

void main() {
  late FakeClient client;
  late AppDatabase db;
  late ItemRepositoryImpl repository;

  setUp(() {
    client = FakeClient();
    db = AppDatabase(NativeDatabase.memory());
    repository = ItemRepositoryImpl(
      client,
      PendingOperationsQueue(db),
      // Only the reconnect-specific tests below need a controllable
      // online/offline stream -- every other test here never touches it.
      FakeConnectivityAdapter(const Stream.empty()),
      () => UserId(userUuid.uuid),
      CachedItemsStore(db),
    );
  });

  tearDown(() => db.close());

  group('ItemRepositoryImpl', () {
    test('byList maps every item to the domain', () async {
      client.handler = (_, _, _) => [
        buildItemDto(),
        buildItemDto(name: 'Bread'),
      ];

      final result = await repository.byList(ListId(listUuid.uuid));

      expect(result.valueOrNull, hasLength(2));
      expect(result.valueOrNull?.first, isA<ShoppingItem>());
    });

    test('add forwards name, quantity and optional tags', () async {
      client.handler = (_, _, _) => buildItemDto(quantity: 3);

      await repository.add(
        listId: ListId(listUuid.uuid),
        name: 'Milk',
        quantity: 3,
        shopId: ShopId(shopUuid.uuid),
        noteText: 'oat',
      );

      final call = client.calls.single;
      expect(call.method, 'add');
      expect(call.args['name'], 'Milk');
      expect(call.args['quantity'], 3);
      expect(call.args['shopId'], shopUuid);
      expect(call.args['noteText'], 'oat');
    });

    test('add omits the optional arguments when they are absent', () async {
      client.handler = (_, _, _) => buildItemDto();

      await repository.add(listId: ListId(listUuid.uuid), name: 'Milk');

      expect(client.calls.single.args['shopId'], isNull);
      expect(client.calls.single.args['noteText'], isNull);
    });

    test(
      'save sends the item back as a DTO, concurrency token included',
      () async {
        client.handler = (_, _, _) => buildItemDto(name: 'Oat milk');
        final item = buildItemDto().toDomain();

        final result = await repository.save(item.copyWith(name: 'Oat milk'));

        final sent = client.calls.single.args['item'] as dto.ShoppingItem;
        expect(sent.name, 'Oat milk');
        expect(sent.updatedAt, testNow);
        expect(result.valueOrNull?.name, 'Oat milk');
      },
    );

    test('a losing optimistic write comes back as a conflict', () async {
      client.handler = (_, _, _) => throw dto.EditConflictException();

      final result = await repository.save(buildItemDto().toDomain());

      expect(result.failureOrNull, const Failure.conflict());
    });

    test('remove sends the item id and returns Ok', () async {
      client.handler = (_, _, _) => null;

      final result = await repository.remove(ItemId(itemUuid.uuid));

      expect(result.isOk, isTrue);
      expect(client.calls.single.args['itemId'], itemUuid);
    });

    test('watchByList seeds with the current items', () async {
      client.handler = (_, method, _) =>
          method == 'byList' ? [buildItemDto()] : const Stream<Never>.empty();

      final first = await repository.watchByList(ListId(listUuid.uuid)).first;

      expect(first.valueOrNull, hasLength(1));
    });

    test(
      'watchByList reports a failed seed instead of closing empty',
      () async {
        client.handler = (_, _, _) => throw dto.NotAMemberException();

        final first = await repository.watchByList(ListId(listUuid.uuid)).first;

        expect(first.failureOrNull, const Failure.unauthorized());
      },
    );
  });

  group('ItemRepositoryImpl — offline retry/queue (Phase C)', () {
    test(
      'a single transient failure retries and succeeds, without queuing',
      () async {
        var attempt = 0;
        client.handler = (_, _, _) {
          attempt++;
          // "Genuinely unreachable" — see isUnreachable in failure_mapper.dart.
          if (attempt == 1) {
            throw const dto.ServerpodClientException('down', -1);
          }
          return buildItemDto(name: 'Milk');
        };

        final result = await repository.add(
          listId: ListId(listUuid.uuid),
          name: 'Milk',
        );

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

        final result = await repository.add(
          listId: ListId(listUuid.uuid),
          name: 'Milk',
        );

        // maxAttempts: 2 in retryOnUnreachable — both calls fail before
        // _guard falls through to onUnreachable.
        expect(client.calls, hasLength(2));
        expect(result.isOk, isTrue);
        expect(result.valueOrNull?.pending, isTrue);

        final queued = await db.select(db.pendingOperations).get();
        expect(queued, hasLength(1));
        expect(queued.single.entityType, PendingEntityType.item);
        expect(queued.single.opType, PendingOpType.create);
      },
    );
  });

  group('ItemRepositoryImpl real-time — reconnect (Phase F)', () {
    test(
      'a WebSocketClosedException mid-stream keeps the last good list and '
      'only re-fetches once reconnected',
      () async {
        final onlineController = StreamController<bool>.broadcast();
        final repo = ItemRepositoryImpl(
          client,
          PendingOperationsQueue(db),
          FakeConnectivityAdapter(onlineController.stream),
          () => UserId(userUuid.uuid),
          CachedItemsStore(db),
        );

        var byListCallCount = 0;
        client.handler = (_, _, _) {
          byListCallCount++;
          return [buildItemDto(name: byListCallCount == 1 ? 'Milk' : 'Bread')];
        };
        final changeControllers = <StreamController<dto.ItemChange>>[];
        client.streamHandler = (_, _, _) {
          final controller = StreamController<dto.ItemChange>();
          changeControllers.add(controller);
          return controller.stream;
        };

        final events = <Result<List<ShoppingItem>>>[];
        final subscription = repo
            .watchByList(ListId(listUuid.uuid))
            .listen(events.add);

        // Same ordering lesson as list_repository_impl_test.dart's own
        // watch test: close the source before cancelling the outer
        // subscription, or an awaited cancel() can deadlock waiting for a
        // generator that only wakes up in response to its own source.
        addTearDown(subscription.cancel);
        addTearDown(() async {
          for (final c in changeControllers) {
            await c.close();
          }
        });
        addTearDown(onlineController.close);

        await Future<void>.delayed(Duration.zero);
        expect(byListCallCount, 1);
        expect(events.single.valueOrNull?.single.name, 'Milk');

        // The live socket dies -- no Err should reach the listener, and the
        // last good list must stay exactly as it was.
        changeControllers.single.addError(
          const dto.WebSocketClosedException(),
        );
        await Future<void>.delayed(Duration.zero);
        expect(events, hasLength(1));

        // Still offline: no re-fetch has happened yet.
        expect(byListCallCount, 1);

        // Reconnect.
        onlineController.add(true);
        await Future<void>.delayed(Duration.zero);

        expect(byListCallCount, 2); // a fresh full snapshot, not a resume
        expect(events.last.valueOrNull?.single.name, 'Bread');
        expect(changeControllers, hasLength(2)); // resubscribed
      },
    );

    test(
      'a NotAMemberException mid-stream still ends with one Err, not '
      'treated as recoverable',
      () async {
        final repo = ItemRepositoryImpl(
          client,
          PendingOperationsQueue(db),
          FakeConnectivityAdapter(const Stream.empty()),
          () => UserId(userUuid.uuid),
          CachedItemsStore(db),
        );

        client.handler = (_, _, _) => [buildItemDto()];
        final changeController = StreamController<dto.ItemChange>();
        client.streamHandler = (_, _, _) => changeController.stream;

        final events = <Result<List<ShoppingItem>>>[];
        final subscription = repo
            .watchByList(ListId(listUuid.uuid))
            .listen(events.add);
        addTearDown(subscription.cancel);
        addTearDown(changeController.close);

        await Future<void>.delayed(Duration.zero);
        changeController.addError(dto.NotAMemberException());
        await Future<void>.delayed(Duration.zero);

        expect(events, hasLength(2)); // seed Ok, then one Err
        expect(events.last.failureOrNull, const Failure.unauthorized());
      },
    );
  });
}
