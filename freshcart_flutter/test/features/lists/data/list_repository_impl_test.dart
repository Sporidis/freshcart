import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/lists/data/list_repository_impl.dart';

import '../../../fakes/dto_builders.dart';
import '../../../fakes/fake_client.dart';

void main() {
  late FakeClient client;
  late ListRepositoryImpl repository;

  setUp(() {
    client = FakeClient();
    repository = ListRepositoryImpl(client);
  });

  group('ListRepositoryImpl success paths', () {
    test('myLists returns domain entities, never DTOs', () {
      client.handler = (_, _, _) => [buildListDto()];

      return repository.myLists().then((result) {
        expect(result.valueOrNull, isA<List<ShoppingList>>());
        expect(result.valueOrNull?.single.name, 'Groceries');
      });
    });

    test('create sends the name and returns the new list', () async {
      client.handler = (_, _, _) => buildListDto(name: 'Weekend');

      final result = await repository.create(name: 'Weekend');

      expect(result.valueOrNull?.name, 'Weekend');
      expect(client.calls.single.endpoint, 'list');
      expect(client.calls.single.method, 'create');
      expect(client.calls.single.args['name'], 'Weekend');
    });

    test('joinByCode sends the validated code string', () async {
      client.handler = (_, _, _) => buildListDto();
      final code = JoinCode.parse('ABC234').valueOrNull!;

      await repository.joinByCode(code);

      expect(client.calls.single.method, 'join');
      expect(client.calls.single.args['joinCode'], 'ABC234');
    });

    test('byId sends the id as a UUID', () async {
      client.handler = (_, _, _) => buildListDto();

      await repository.byId(ListId(listUuid.uuid));

      expect(client.calls.single.args['listId'], listUuid);
    });
  });

  group('ListRepositoryImpl failure translation', () {
    test('a server exception becomes an Err, not a throw', () async {
      client.handler = (_, _, _) => throw dto.NotAMemberException();

      final result = await repository.byId(ListId(listUuid.uuid));

      expect(result, const Err<ShoppingList>(Failure.unauthorized()));
    });

    test('a missing list becomes notFound', () async {
      client.handler = (_, _, _) => throw dto.ListNotFoundException();

      expect(
        (await repository.byId(ListId(listUuid.uuid))).failureOrNull,
        const Failure.notFound(),
      );
    });

    test('a transport error becomes a network failure', () async {
      client.handler = (_, _, _) =>
          throw dto.ServerpodClientInternalServerError();

      expect(
        (await repository.myLists()).failureOrNull,
        isA<NetworkFailure>(),
      );
    });

    test('a broken server contract surfaces as unexpected', () async {
      // A list with a malformed join code makes the mapper throw StateError.
      client.handler = (_, _, _) => buildListDto(joinCode: 'bad');

      expect(
        (await repository.myLists()).failureOrNull,
        isA<UnexpectedFailure>(),
      );
    });
  });

  group('ListRepositoryImpl real-time', () {
    test('watch is not implemented before phase 8', () {
      expect(
        () => repository.watch(ListId(listUuid.uuid)),
        throwsUnimplementedError,
      );
    });
  });
}
