import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/offline/cache/cached_items_store.dart';
import 'package:freshcart_flutter/core/offline/cache/cached_lists_store.dart';
import 'package:freshcart_flutter/core/offline/database/app_database.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_operations_queue.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_operations_table.dart';
import 'package:freshcart_flutter/core/offline/queue/shopping_item_queue_payload.dart';
import 'package:freshcart_flutter/core/offline/replay/queue_drainer.dart';
import 'package:freshcart_flutter/features/items/data/repositories/item_repository_impl.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/list_repository_impl.dart';

import '../../../fakes/dto_builders.dart';
import '../../../fakes/fake_client.dart';
import '../../../fakes/fake_connectivity_adapter.dart';
import '../../../fakes/fake_item_repository.dart';
import '../../../fakes/fake_list_repository.dart';

void main() {
  group('QueueDrainer.drain', () {
    late AppDatabase db;
    late PendingOperationsQueue queue;
    late FakeItemRepository items;
    late FakeListRepository lists;
    late QueueDrainer drainer;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      queue = PendingOperationsQueue(db);
      items = FakeItemRepository();
      lists = FakeListRepository();
      drainer = QueueDrainer(queue, items, lists);
    });

    tearDown(() => db.close());

    test(
      'replays a create then an edit in order, rewriting the edit\'s '
      'itemId once the create is known to have succeeded',
      () async {
        items.addResult = Ok(buildItem(id: 'real-item-id'));

        await queue.enqueue(
          entityType: PendingEntityType.item,
          opType: PendingOpType.create,
          tempId: 'temp-item-1',
          payload: const {
            'listId': '00000000-0000-4000-8000-000000000001',
            'name': 'Milk',
            'quantity': 1,
            'shopId': null,
            'noteText': null,
          },
        );
        final editedItem = buildItem(
          id: 'temp-item-1',
        ).copyWith(name: 'Oat milk');
        await queue.enqueue(
          entityType: PendingEntityType.item,
          opType: PendingOpType.edit,
          payload: editedItem.toQueuePayload(),
        );

        final conflicted = await drainer.drain();

        expect(conflicted, isEmpty);
        expect(items.addCalls, hasLength(1));
        expect(items.savedItems, hasLength(1));
        expect(items.savedItems.single.id, ItemId('real-item-id'));
        expect(await queue.getAll(), isEmpty);
      },
    );

    test(
      'rewrites a listId that points at a list created earlier in the '
      'same drain',
      () async {
        lists.createResult = Ok(buildList(id: 'real-list-id'));
        items.addResult = Ok(buildItem(id: 'real-item-id'));

        await queue.enqueue(
          entityType: PendingEntityType.list,
          opType: PendingOpType.create,
          tempId: 'temp-list-1',
          payload: const {'name': 'Groceries'},
        );
        await queue.enqueue(
          entityType: PendingEntityType.item,
          opType: PendingOpType.create,
          tempId: 'temp-item-1',
          payload: const {
            'listId': 'temp-list-1',
            'name': 'Milk',
            'quantity': 1,
            'shopId': null,
            'noteText': null,
          },
        );

        final conflicted = await drainer.drain();

        expect(conflicted, isEmpty);
        expect(items.addCalls.single.listId, ListId('real-list-id'));
        expect(await queue.getAll(), isEmpty);
      },
    );

    test(
      'drops a conflicted op, reports it, but still clears it from the '
      'queue (server wins)',
      () async {
        items.removeResult = const Err(Failure.conflict());
        await queue.enqueue(
          entityType: PendingEntityType.item,
          opType: PendingOpType.remove,
          payload: const {'itemId': 'item-1'},
        );

        final conflicted = await drainer.drain();

        expect(conflicted, hasLength(1));
        expect(conflicted.single.opType, PendingOpType.remove);
        expect(await queue.getAll(), isEmpty);
      },
    );

    test(
      'leaves a non-conflict failure queued for the next reconnect',
      () async {
        items.removeResult = const Err(Failure.network());
        await queue.enqueue(
          entityType: PendingEntityType.item,
          opType: PendingOpType.remove,
          payload: const {'itemId': 'item-1'},
        );

        final conflicted = await drainer.drain();

        expect(conflicted, isEmpty);
        expect(await queue.getAll(), hasLength(1));
      },
    );
  });

  // The fakes above can't catch this: the re-queuing happens inside the
  // real repositories' offline fallback, so this group drains through them.
  group('QueueDrainer.drain with the real repositories', () {
    late AppDatabase db;
    late PendingOperationsQueue queue;
    late FakeClient client;
    late QueueDrainer drainer;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      queue = PendingOperationsQueue(db);
      client = FakeClient();
      final connectivity = FakeConnectivityAdapter(const Stream.empty());
      UserId currentUserId() => UserId(userUuid.uuid);
      final items = ItemRepositoryImpl(
        client,
        queue,
        connectivity,
        currentUserId,
        CachedItemsStore(db),
        queueWhenUnreachable: false,
      );
      final lists = ListRepositoryImpl(
        client,
        queue,
        connectivity,
        currentUserId,
        CachedListsStore(db),
        queueWhenUnreachable: false,
      );
      drainer = QueueDrainer(queue, items, lists);
    });

    tearDown(() => db.close());

    test(
      'a list op sent while the server is still unreachable stays queued '
      'as the original, not as a copy',
      () async {
        await queue.enqueue(
          entityType: PendingEntityType.list,
          opType: PendingOpType.leave,
          payload: {'id': listUuid.uuid},
        );
        final original = (await queue.getAll()).single;
        client.handler = (_, _, _) =>
            throw const dto.ServerpodClientException('down', -1);

        await drainer.drain();

        final after = await queue.getAll();
        expect(after, hasLength(1));
        expect(after.single.id, original.id);
      },
    );

    test(
      'a server that is still unreachable leaves the original op queued, '
      'without queuing a copy of it',
      () async {
        await queue.enqueue(
          entityType: PendingEntityType.item,
          opType: PendingOpType.remove,
          payload: {'itemId': listUuid.uuid},
        );
        final original = (await queue.getAll()).single;
        client.handler = (_, _, _) =>
            throw const dto.ServerpodClientException('down', -1);

        await drainer.drain();

        final after = await queue.getAll();
        expect(after, hasLength(1));
        expect(after.single.id, original.id);
      },
    );
  });
}
