import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/items/data/item_realtime_source.dart';
import 'package:freshcart_flutter/features/items/data/mappers/shopping_item_mapper.dart';

import '../../../fakes/dto_builders.dart';

void main() {
  final otherUuid = dto.UuidValue.withValidation(
    '00000000-0000-4000-8000-00000000000f',
  );

  dto.ItemChange upsert(dto.ShoppingItem item) => dto.ItemChange(
    kind: dto.ItemChangeKind.upserted,
    itemId: item.id!,
    item: item,
    actorId: userUuid,
  );

  group('ItemRealtimeSource.applyChange', () {
    test('replaces an item it already knows', () {
      final current = [buildItemDto(name: 'Milk').toDomain()];

      final merged = ItemRealtimeSource.applyChange(
        current,
        upsert(buildItemDto(name: 'Oat milk')),
      );

      expect(merged, hasLength(1));
      expect(merged.single.name, 'Oat milk');
    });

    test('appends an item it has never seen', () {
      // How another person's new item arrives.
      final current = [buildItemDto(name: 'Milk').toDomain()];
      final theirs = dto.ShoppingItem(
        id: otherUuid,
        listId: listUuid,
        name: 'Bread',
        quantity: 1,
        isChecked: false,
        addedBy: userUuid,
        createdAt: testNow,
        updatedAt: testNow,
      );

      final merged = ItemRealtimeSource.applyChange(current, upsert(theirs));

      expect(merged.map((i) => i.name), ['Milk', 'Bread']);
    });

    test('drops a removed item', () {
      final current = [buildItemDto(name: 'Milk').toDomain()];

      final merged = ItemRealtimeSource.applyChange(
        current,
        dto.ItemChange(
          kind: dto.ItemChangeKind.removed,
          itemId: itemUuid,
          actorId: userUuid,
        ),
      );

      expect(merged, isEmpty);
    });

    test('ignores a removal for something it does not hold', () {
      final current = [buildItemDto(name: 'Milk').toDomain()];

      final merged = ItemRealtimeSource.applyChange(
        current,
        dto.ItemChange(
          kind: dto.ItemChangeKind.removed,
          itemId: otherUuid,
          actorId: userUuid,
        ),
      );

      expect(merged, hasLength(1));
    });

    test('ignores a malformed upsert that carries no item', () {
      // Dropping it is safer than guessing; the next full read corrects things.
      final current = [buildItemDto(name: 'Milk').toDomain()];

      final merged = ItemRealtimeSource.applyChange(
        current,
        dto.ItemChange(
          kind: dto.ItemChangeKind.upserted,
          itemId: itemUuid,
          actorId: userUuid,
        ),
      );

      expect(merged.single.name, 'Milk');
    });

    test('does not mutate the list it was given', () {
      final current = <ShoppingItem>[buildItemDto(name: 'Milk').toDomain()];

      ItemRealtimeSource.applyChange(
        current,
        dto.ItemChange(
          kind: dto.ItemChangeKind.removed,
          itemId: itemUuid,
          actorId: userUuid,
        ),
      );

      expect(current, hasLength(1));
    });
  });
}
