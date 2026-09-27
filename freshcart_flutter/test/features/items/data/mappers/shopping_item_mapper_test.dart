import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_flutter/features/items/data/mappers/shopping_item_mapper.dart';

import '../../../../fakes/dto_builders.dart';

void main() {
  group('ShoppingItemDtoX.toDomain', () {
    test('maps a plain unchecked item', () {
      final item = buildItemDto().toDomain();

      expect(item.id.value, itemUuid.uuid);
      expect(item.listId.value, listUuid.uuid);
      expect(item.name, 'Milk');
      expect(item.quantity, 1);
      expect(item.isChecked, isFalse);
      expect(item.addedBy.value, userUuid.uuid);
      expect(item.shopId, isNull);
      expect(item.note, isNull);
      expect(item.checkedBy, isNull);
      expect(item.checkedAt, isNull);
    });

    test('maps the optional shop tag and note', () {
      final item = buildItemDto(
        shopId: shopUuid,
        note: dto.Note(
          text: 'the oat one',
          authorId: userUuid,
          updatedAt: testNow,
        ),
      ).toDomain();

      expect(item.shopId?.value, shopUuid.uuid);
      expect(item.hasShop, isTrue);
      expect(item.note?.text, 'the oat one');
      expect(item.hasNote, isTrue);
    });

    test('maps a checked item with its actor and timestamp', () {
      final item = buildItemDto(
        isChecked: true,
        checkedBy: userUuid,
        checkedAt: testNow,
      ).toDomain();

      expect(item.isChecked, isTrue);
      expect(item.checkedBy?.value, userUuid.uuid);
      expect(item.checkedAt, testNow);
    });

    test('rejects an item with no id', () {
      final noId = dto.ShoppingItem(
        listId: listUuid,
        name: 'Milk',
        quantity: 1,
        isChecked: false,
        addedBy: userUuid,
        createdAt: testNow,
        updatedAt: testNow,
      );
      expect(noId.toDomain, throwsA(isA<StateError>()));
    });
  });

  group('ShoppingItemX.toDto', () {
    test('round-trips through the wire type unchanged', () {
      final original = buildItemDto(
        quantity: 3,
        sortOrder: 42,
        shopId: shopUuid,
        note: dto.Note(text: 'oat', authorId: userUuid, updatedAt: testNow),
      ).toDomain();

      expect(original.toDto().toDomain(), original);
    });

    test('carries updatedAt across, since it is the concurrency token', () {
      // If the mapper dropped or refreshed this, the server could never detect
      // a conflicting write and optimistic UI would silently lose edits.
      final domain = buildItemDto().toDomain();
      expect(domain.toDto().updatedAt, testNow);
    });

    test('carries sortOrder across', () {
      // If the mapper dropped this, every save -- a rename, a note, a tick --
      // would silently reset the row's position back to the mapper's default,
      // whatever the drag it had actually landed at.
      final domain = buildItemDto(sortOrder: 42).toDomain();
      expect(domain.toDto().sortOrder, 42);
    });

    test('leaves an untagged, unchecked item null on the wire', () {
      final wire = buildItemDto().toDomain().toDto();
      expect(wire.shopId, isNull);
      expect(wire.note, isNull);
      expect(wire.checkedBy, isNull);
      expect(wire.checkedAt, isNull);
    });
  });
}
