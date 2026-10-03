import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/sync/data/sources/database/app_database.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/pending_operations_queue.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/pending_operations_table.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/queued_item_changes.dart';
import 'package:freshcart_flutter/features/sync/data/sources/queue/shopping_item_queue_payload.dart';

import '../../../../../fakes/fake_item_repository.dart';

void main() {
  late AppDatabase db;
  late PendingOperationsQueue queue;

  const listIdValue = '00000000-0000-4000-8000-000000000001';
  final listId = ListId(listIdValue);
  UserId me() => UserId('user-1');

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    queue = PendingOperationsQueue(db);
  });
  tearDown(() => db.close());

  Future<List<ShoppingItem>> replay(List<ShoppingItem> items) async =>
      applyQueuedItemChanges(items, await queue.getAll(), listId, me: me);

  final milk = buildItem(id: 'milk', name: 'Milk');
  final bread = buildItem(id: 'bread', name: 'Bread');

  test(
    'with nothing queued, the items are untouched and not pending',
    () async {
      final out = await replay([milk, bread]);
      expect(out, [milk, bread]);
      expect(out.any((i) => i.pending), isFalse);
    },
  );

  test(
    'an item added offline shows, pending, under its temporary id',
    () async {
      await queue.enqueue(
        entityType: PendingEntityType.item,
        opType: PendingOpType.create,
        tempId: 'temp-1',
        payload: const {
          'listId': listIdValue,
          'name': 'Eggs',
          'quantity': 6,
          'shopId': null,
          'noteText': null,
        },
      );

      final out = await replay([milk]);

      final eggs = out.singleWhere((i) => i.name == 'Eggs');
      expect(eggs.id.value, 'temp-1');
      expect(eggs.quantity, 6);
      expect(eggs.pending, isTrue);
      expect(eggs.addedBy, me());
      expect(out.singleWhere((i) => i.name == 'Milk').pending, isFalse);
    },
  );

  test(
    'an offline tick (an edit) replaces the row and marks it pending',
    () async {
      await queue.enqueue(
        entityType: PendingEntityType.item,
        opType: PendingOpType.edit,
        payload: milk
            .toggleChecked(by: me(), at: DateTime.utc(2026, 10))
            .toQueuePayload(),
      );

      final row = (await replay([milk, bread])).singleWhere(
        (i) => i.id == milk.id,
      );
      expect(row.isChecked, isTrue);
      expect(row.pending, isTrue);
    },
  );

  test('an edit to an item added offline lands on that new row', () async {
    await queue.enqueue(
      entityType: PendingEntityType.item,
      opType: PendingOpType.create,
      tempId: 'temp-1',
      payload: const {
        'listId': listIdValue,
        'name': 'Eggs',
        'quantity': 1,
        'shopId': null,
        'noteText': null,
      },
    );
    await queue.enqueue(
      entityType: PendingEntityType.item,
      opType: PendingOpType.edit,
      payload: buildItem(
        id: 'temp-1',
        name: 'Eggs',
        quantity: 12,
      ).toQueuePayload(),
    );

    final eggs = (await replay(const [])).single;
    expect(eggs.quantity, 12);
    expect(eggs.pending, isTrue);
  });

  test('offline deletes hide their rows, one or many', () async {
    final cheese = buildItem(id: 'cheese', name: 'Cheese');
    await queue.enqueue(
      entityType: PendingEntityType.item,
      opType: PendingOpType.remove,
      payload: const {'itemId': 'milk'},
    );
    await queue.enqueue(
      entityType: PendingEntityType.item,
      opType: PendingOpType.removeMany,
      payload: const {
        'listId': listIdValue,
        'ids': ['bread'],
      },
    );

    final out = await replay([milk, bread, cheese]);
    expect(out.map((i) => i.name), ['Cheese']);
  });

  test('clearing checked offline hides the checked rows', () async {
    final done = buildItem(id: 'done', name: 'Done', isChecked: true);
    await queue.enqueue(
      entityType: PendingEntityType.item,
      opType: PendingOpType.clearChecked,
      payload: const {'listId': listIdValue},
    );

    final out = await replay([milk, done]);
    expect(out.map((i) => i.name), ['Milk']);
  });

  test('moving offline re-tags the rows and marks them pending', () async {
    await queue.enqueue(
      entityType: PendingEntityType.item,
      opType: PendingOpType.moveMany,
      payload: const {
        'listId': listIdValue,
        'ids': ['milk'],
        'shopId': 'shop-1',
      },
    );

    final out = await replay([milk, bread]);
    final moved = out.singleWhere((i) => i.id == milk.id);
    expect(moved.shopId, ShopId('shop-1'));
    expect(moved.pending, isTrue);
    expect(out.singleWhere((i) => i.id == bread.id).pending, isFalse);
  });

  test("another list's queued changes are left out", () async {
    await queue.enqueue(
      entityType: PendingEntityType.item,
      opType: PendingOpType.create,
      tempId: 'temp-other',
      payload: const {
        'listId': '00000000-0000-4000-8000-000000000099',
        'name': 'Nails',
        'quantity': 1,
        'shopId': null,
        'noteText': null,
      },
    );

    final out = await replay([milk]);
    expect(out.map((i) => i.name), ['Milk']);
  });
}
