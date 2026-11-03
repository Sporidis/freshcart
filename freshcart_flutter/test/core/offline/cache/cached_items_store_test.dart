import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/offline/cache/cached_items_store.dart';
import 'package:freshcart_flutter/core/offline/database/app_database.dart';
import 'package:freshcart_flutter/features/items/data/mappers/shopping_item_mapper.dart';

import '../../../fakes/dto_builders.dart';

void main() {
  late AppDatabase db;
  late CachedItemsStore store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = CachedItemsStore(db);
  });

  tearDown(() => db.close());

  group('CachedItemsStore', () {
    test('readForList returns null for a list that was never cached', () async {
      expect(await store.readForList(ListId(listUuid.uuid)), isNull);
    });

    test('replaceForList then readForList round-trips every item', () async {
      final items = [
        buildItemDto().toDomain(),
        buildItemDto(name: 'Bread').toDomain().copyWith(
          id: ItemId(userUuid.uuid), // any second, distinct id
        ),
      ];

      await store.replaceForList(ListId(listUuid.uuid), items);
      final cached = await store.readForList(ListId(listUuid.uuid));

      expect(cached, hasLength(2));
      expect(cached!.map((i) => i.name), containsAll(['Milk', 'Bread']));
    });

    test(
      'replaceForList drops rows no longer present, not just adds',
      () async {
        final listId = ListId(listUuid.uuid);
        await store.replaceForList(listId, [
          buildItemDto(name: 'Milk').toDomain(),
        ]);
        await store.replaceForList(listId, [
          buildItemDto(name: 'Bread').toDomain(),
        ]);

        final cached = await store.readForList(listId);
        expect(cached!.map((i) => i.name), ['Bread']);
      },
    );

    test(
      'a list saved as empty reads back empty, not as never saved',
      () async {
        // The offline bug: an empty list opened without internet showed
        // "something went wrong", because nothing saved looked like this.
        final listId = ListId(listUuid.uuid);
        await store.replaceForList(listId, []);

        expect(await store.readForList(listId), isEmpty);
      },
    );

    test('a list emptied since its last save reads back empty', () async {
      final listId = ListId(listUuid.uuid);
      await store.replaceForList(listId, [buildItemDto().toDomain()]);
      await store.replaceForList(listId, []);

      expect(await store.readForList(listId), isEmpty);
    });

    test('replaceForList only touches rows for its own list id', () async {
      final otherListId = ListId(userUuid.uuid);
      await store.replaceForList(
        ListId(listUuid.uuid),
        [buildItemDto().toDomain()],
      );
      await store.replaceForList(otherListId, []);

      final cached = await store.readForList(ListId(listUuid.uuid));
      expect(cached, hasLength(1));
      expect(await store.readForList(otherListId), isEmpty);
    });

    test('clear forgets every list, empty ones too', () async {
      final listId = ListId(listUuid.uuid);
      await store.replaceForList(listId, []);
      await store.clear();

      expect(await store.readForList(listId), isNull);
    });
  });
}
