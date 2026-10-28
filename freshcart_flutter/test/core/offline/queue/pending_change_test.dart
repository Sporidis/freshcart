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

  group('PendingChange.withRealIds', () {
    const realIds = {
      'temp-list-1': _listId,
      'temp-item-1': _itemId,
    };

    for (final (change, json) in cases) {
      test('${change.runtimeType} without temporary ids stays the same', () {
        expect(change.withRealIds(realIds).toJson(), json);
      });
    }

    test('ItemsRemoved rewrites the temporary ids inside its list', () {
      final change = ItemsRemoved(ListId('temp-list-1'), [
        ItemId('temp-item-1'),
        ItemId(_otherItemId),
      ]);

      expect(change.withRealIds(realIds).toJson(), {
        'listId': _listId,
        'ids': [_itemId, _otherItemId],
      });
    });

    test('ItemsMovedToShop rewrites the temporary ids inside its list', () {
      final change = ItemsMovedToShop(
        ListId(_listId),
        [ItemId('temp-item-1')],
        ShopId(_shopId),
      );

      expect(change.withRealIds(realIds).toJson(), {
        'listId': _listId,
        'ids': [_itemId],
        'shopId': _shopId,
      });
    });

    test(
      'ItemCreated in a new list gets the real list id, keeps its tempId',
      () {
        final change = ItemCreated(
          tempId: 'temp-item-2',
          listId: ListId('temp-list-1'),
          name: 'Milk',
          quantity: 1,
        );

        final rewritten = change.withRealIds(realIds);

        expect(rewritten.tempId, 'temp-item-2');
        expect(rewritten.toJson()['listId'], _listId);
      },
    );

    test('ItemEdited rewrites both the item id and its list id', () {
      final change = ItemEdited(
        buildItem(id: 'temp-item-1', listId: 'temp-list-1'),
      );

      final json = change.withRealIds(realIds).toJson();

      expect(json['itemId'], _itemId);
      expect(json['listId'], _listId);
    });

    test('ListRenamed for a new list gets the real list id', () {
      final change = ListRenamed(ListId('temp-list-1'), 'Weekend');

      expect(change.withRealIds(realIds).toJson(), {
        'id': _listId,
        'name': 'Weekend',
      });
    });
  });
}
