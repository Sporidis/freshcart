import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/items/data/item_repository_impl.dart';
import 'package:freshcart_flutter/features/items/data/mappers/shopping_item_mapper.dart';

import '../../../fakes/dto_builders.dart';
import '../../../fakes/fake_client.dart';

void main() {
  late FakeClient client;
  late ItemRepositoryImpl repository;

  setUp(() {
    client = FakeClient();
    repository = ItemRepositoryImpl(client);
  });

  group('ItemRepositoryImpl', () {
    test('byList maps every item to the domain', () async {
      client.handler = (_, _, _) => [
        buildItemDto(),
        buildItemDto(name: 'Bread'),
      ];

      final result = await repository.byList(ListId(listUuid.uuid));

      expect(result.valueOrNull, hasLength(2));
      expect(result.valueOrNull?.first, isA<ShoppingItem>());
    });

    test('add forwards name, quantity and optional tags', () async {
      client.handler = (_, _, _) => buildItemDto(quantity: 3);

      await repository.add(
        listId: ListId(listUuid.uuid),
        name: 'Milk',
        quantity: 3,
        shopId: ShopId(shopUuid.uuid),
        noteText: 'oat',
      );

      final call = client.calls.single;
      expect(call.method, 'add');
      expect(call.args['name'], 'Milk');
      expect(call.args['quantity'], 3);
      expect(call.args['shopId'], shopUuid);
      expect(call.args['noteText'], 'oat');
    });

    test('add omits the optional arguments when they are absent', () async {
      client.handler = (_, _, _) => buildItemDto();

      await repository.add(listId: ListId(listUuid.uuid), name: 'Milk');

      expect(client.calls.single.args['shopId'], isNull);
      expect(client.calls.single.args['noteText'], isNull);
    });

    test(
      'save sends the item back as a DTO, concurrency token included',
      () async {
        client.handler = (_, _, _) => buildItemDto(name: 'Oat milk');
        final item = buildItemDto().toDomain();

        final result = await repository.save(item.copyWith(name: 'Oat milk'));

        final sent = client.calls.single.args['item'] as dto.ShoppingItem;
        expect(sent.name, 'Oat milk');
        expect(sent.updatedAt, testNow);
        expect(result.valueOrNull?.name, 'Oat milk');
      },
    );

    test('a losing optimistic write comes back as a conflict', () async {
      client.handler = (_, _, _) => throw dto.EditConflictException();

      final result = await repository.save(buildItemDto().toDomain());

      expect(result.failureOrNull, const Failure.conflict());
    });

    test('remove sends the item id and returns Ok', () async {
      client.handler = (_, _, _) => null;

      final result = await repository.remove(ItemId(itemUuid.uuid));

      expect(result.isOk, isTrue);
      expect(client.calls.single.args['itemId'], itemUuid);
    });

    test('watchByList seeds with the current items', () async {
      client.handler = (_, method, _) =>
          method == 'byList' ? [buildItemDto()] : const Stream<Never>.empty();

      final first = await repository.watchByList(ListId(listUuid.uuid)).first;

      expect(first.valueOrNull, hasLength(1));
    });

    test(
      'watchByList reports a failed seed instead of closing empty',
      () async {
        client.handler = (_, _, _) => throw dto.NotAMemberException();

        final first = await repository.watchByList(ListId(listUuid.uuid)).first;

        expect(first.failureOrNull, const Failure.unauthorized());
      },
    );
  });
}
