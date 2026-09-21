import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/sync/data/app_database.dart';
import 'package:freshcart_flutter/features/sync/data/pending_operations_queue.dart';
import 'package:freshcart_flutter/features/sync/data/pending_operations_table.dart';
import 'package:freshcart_flutter/features/sync/data/queue_drainer.dart';
import 'package:freshcart_flutter/features/sync/data/shopping_item_queue_payload.dart';

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
}
