import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/lists/data/mappers/shopping_list_mapper.dart';
import 'package:freshcart_flutter/features/sync/data/sources/cache/cached_lists_store.dart';
import 'package:freshcart_flutter/features/sync/data/sources/cache/shopping_list_cache_payload.dart';
import 'package:freshcart_flutter/features/sync/data/sources/database/app_database.dart';

import '../../../../../fakes/dto_builders.dart';

void main() {
  late AppDatabase db;
  late CachedListsStore store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = CachedListsStore(db);
  });

  tearDown(() => db.close());

  group('CachedListsStore', () {
    test('read returns null for a list that was never cached', () async {
      expect(await store.read(ListId(listUuid.uuid)), isNull);
    });

    test('readAll returns null when nothing has ever been cached', () async {
      expect(await store.readAll(), isNull);
    });

    test(
      'upsert then read round-trips the full list, members included',
      () async {
        final list = buildListDto(
          members: [buildMemberDto(displayName: 'Mom')],
        ).toDomain();

        await store.upsert(list);
        final cached = await store.read(list.id);

        expect(cached, isNotNull);
        expect(cached!.name, list.name);
        expect(cached.joinCode, list.joinCode);
        expect(cached.members.single.displayName, 'Mom');
      },
    );

    test('upsert replaces an existing row for the same list id', () async {
      final list = buildListDto().toDomain();
      await store.upsert(list);
      await store.upsert(list.copyWith(name: 'Renamed'));

      final all = await store.readAll();
      expect(all, hasLength(1));
      expect(all!.single.name, 'Renamed');
    });

    test(
      'replaceAll replaces the whole cached set, not just adds to it',
      () async {
        final first = buildListDto(name: 'Old').toDomain();
        await store.upsert(first);

        final second = buildListDto(name: 'New').toDomain().copyWith(
          id: ListId(itemUuid.uuid), // any second, distinct id
        );
        await store.replaceAll([second]);

        final all = await store.readAll();
        expect(all!.map((l) => l.name), ['New']);
      },
    );
  });

  group('ShoppingListCachePayload', () {
    test('round-trips through JSON without loss', () {
      final list = buildListDto(
        members: [buildMemberDto(displayName: 'Dad')],
      ).toDomain();

      final rebuilt = shoppingListFromCachePayload(list.toCachePayload());

      expect(rebuilt, list);
    });
  });
}
