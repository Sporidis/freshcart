import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/offline/database/app_database.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_entity_type.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_op_type.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_operations_queue.dart';
import 'package:freshcart_flutter/features/items/data/repositories/offline_item_repository.dart';

import '../../../../fakes/fake_item_repository.dart';

void main() {
  late AppDatabase db;
  late PendingOperationsQueue queue;
  late FakeItemRepository remote;
  late OfflineItemRepository repository;
  final me = UserId('00000000-0000-4000-8000-0000000000aa');
  final list = ListId('00000000-0000-4000-8000-000000000001');

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    queue = PendingOperationsQueue(db);
    remote = FakeItemRepository();
    repository = OfflineItemRepository(remote, queue, () => me);
  });

  tearDown(() => db.close());

  group('add', () {
    test('online: the server answer, nothing queued', () async {
      final saved = buildItem(id: 'real-id', name: 'Milk');
      remote.addResult = Ok(saved);

      final result = await repository.add(listId: list, name: 'Milk');

      expect(result.valueOrNull, saved);
      expect(await queue.getAll(), isEmpty);
    });

    test('offline: queues a create and answers with a pending item', () async {
      remote.addResult = const Err(Failure.network());

      final result = await repository.add(
        listId: list,
        name: 'Milk',
        quantity: 2,
        noteText: 'oat',
      );

      final item = result.valueOrNull!;
      expect(item.pending, isTrue);
      expect(item.name, 'Milk');
      expect(item.quantity, 2);
      expect(item.note?.text, 'oat');
      expect(item.addedBy, me);

      final op = (await queue.getAll()).single;
      expect(op.entityType, PendingEntityType.item);
      expect(op.opType, PendingOpType.create);
      // Later offline changes to this item (checking it) find it by the
      // same temporary id, so the queue and the screen must agree.
      expect(op.tempId, item.id.value);
    });

    test('any other failure is passed on, and nothing is queued', () async {
      remote.addResult = const Err(Failure.validation('name', 'too long'));

      final result = await repository.add(listId: list, name: 'Milk');

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(await queue.getAll(), isEmpty);
    });
  });
}
