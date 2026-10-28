import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_change.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_entity_type.dart';
import 'package:freshcart_flutter/core/offline/queue/pending_op_type.dart';
import 'package:freshcart_flutter/core/offline/queue/shopping_item_queue_payload.dart';

import '../../../fakes/fake_item_repository.dart';

const _listId = '00000000-0000-4000-8000-000000000001';
const _itemId = '00000000-0000-4000-8000-0000000000aa';
const _otherItemId = '00000000-0000-4000-8000-0000000000bb';
const _shopId = '00000000-0000-4000-8000-0000000000cc';

/// Stores [change] the way the queue does (JSON text) and reads it back.
PendingChange _throughQueue(PendingChange change) => PendingChange.fromQueue(
  change.entityType,
  change.opType,
  jsonDecode(jsonEncode(change.toJson())) as Map<String, Object?>,
  tempId: change.tempId,
);

void main() {
  // Each change next to the exact JSON the offline repositories wrote
  // before PendingChange existed. Rows like these may still be queued on
  // a phone, so the keys must never change.
  final cases = <(PendingChange, Map<String, Object?>)>[
    (
      ItemCreated(
        tempId: 'temp-item-1',
        listId: ListId(_listId),
        name: 'Milk',
        quantity: 2,
        shopId: ShopId(_shopId),
        noteText: 'the oat one',
      ),
      {
        'listId': _listId,
        'name': 'Milk',
        'quantity': 2,
        'shopId': _shopId,
        'noteText': 'the oat one',
      },
    ),
    (
      ItemCreated(
        tempId: 'temp-item-2',
        listId: ListId(_listId),
        name: 'Bread',
        quantity: 1,
      ),
      {
        'listId': _listId,
        'name': 'Bread',
        'quantity': 1,
        'shopId': null,
        'noteText': null,
      },
    ),
    (ItemEdited(buildItem()), buildItem().toQueuePayload()),
    (ItemRemoved(ItemId(_itemId)), {'itemId': _itemId}),
    (CheckedItemsCleared(ListId(_listId)), {'listId': _listId}),
    (
      ItemsRemoved(ListId(_listId), [ItemId(_itemId), ItemId(_otherItemId)]),
      {
        'listId': _listId,
        'ids': [_itemId, _otherItemId],
      },
    ),
    (
      ItemsMovedToShop(ListId(_listId), [ItemId(_itemId)], ShopId(_shopId)),
      {
        'listId': _listId,
        'ids': [_itemId],
        'shopId': _shopId,
      },
    ),
    (
      ItemsMovedToShop(ListId(_listId), [ItemId(_itemId)], null),
      {
        'listId': _listId,
        'ids': [_itemId],
        'shopId': null,
      },
    ),
    (
      const ListCreated(tempId: 'temp-list-1', name: 'Groceries'),
      {'name': 'Groceries'},
    ),
    (
      ListRenamed(ListId(_listId), 'Weekend'),
      {'id': _listId, 'name': 'Weekend'},
    ),
    (
      ClearCheckedAfterShoppingSet(ListId(_listId), value: true),
      {'id': _listId, 'value': true},
    ),
    (ListLeft(ListId(_listId)), {'id': _listId}),
    (ListDeleted(ListId(_listId)), {'id': _listId}),
    (
      MemberRemoved(ListId(_listId), UserId('user-2')),
      {'id': _listId, 'userId': 'user-2'},
    ),
    (
      OwnershipTransferred(ListId(_listId), UserId('user-2')),
      {'id': _listId, 'userId': 'user-2'},
    ),
  ];

  group('PendingChange', () {
    for (final (change, json) in cases) {
      final name = '${change.runtimeType} (${change.opType.name})';

      test('$name writes the same JSON as before', () {
        expect(change.toJson(), json);
      });

      test('$name comes back unchanged through the queue', () {
        final decoded = _throughQueue(change);

        expect(decoded.runtimeType, change.runtimeType);
        expect(decoded.entityType, change.entityType);
        expect(decoded.opType, change.opType);
        expect(decoded.tempId, change.tempId);
        expect(decoded.toJson(), json);
      });
    }

    test('a combination that cannot exist throws', () {
      expect(
        () => PendingChange.fromQueue(
          PendingEntityType.item,
          PendingOpType.rename,
          {'id': _itemId, 'name': 'Milk'},
        ),
        throwsUnsupportedError,
      );
    });

    test('a create without a tempId throws', () {
      expect(
        () => PendingChange.fromQueue(
          PendingEntityType.list,
          PendingOpType.create,
          {'name': 'Groceries'},
        ),
        throwsArgumentError,
      );
    });
  });
}
