import 'dart:async';

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
    test('watch seeds with the current list', () async {
      // Only the seed is exercised here — .first cancels the subscription as
      // soon as it arrives, before the source ever reaches the streaming
      // watchList call, so no streamHandler is needed for this one.
      client.handler = (_, _, _) => buildListDto();

      final first = await repository.watch(ListId(listUuid.uuid)).first;

      expect(first.valueOrNull?.name, 'Groceries');
    });

    test('watch follows renames and membership changes live', () async {
      // Streaming methods are a distinct transport path in a real Serverpod
      // client (a WebSocket, not an HTTP call), so FakeClient answers them
      // through streamHandler rather than handler.
      final updates = StreamController<dto.ShoppingList>();
      client.handler = (_, _, _) => buildListDto();
      client.streamHandler = (_, _, _) => updates.stream;

      final events = <Result<ShoppingList>>[];
      final subscription = repository
          .watch(ListId(listUuid.uuid))
          .listen(events.add);

      // Teardown order matters here and is easy to get backwards: cancelling
      // the *outer* subscription while it is suspended awaiting the *inner*
      // (`updates`) stream does not unwind that inner await, so an awaited
      // `subscription.cancel()` would deadlock forever waiting for a cancel
      // that can only complete once `updates` itself is done. Closing the
      // source first lets the generator finish naturally; cancelling the
      // already-finished subscription after that is then a no-op. (In the
      // real app this never bites: Riverpod's `ref.onDispose` never awaits its
      // callback, so `ref.onDispose(subscription.cancel)` fires-and-forgets
      // the very same call that would deadlock here if awaited.)
      addTearDown(subscription.cancel);
      addTearDown(updates.close);

      await Future<void>.delayed(Duration.zero);

      updates.add(buildListDto(name: 'Weekend shop'));
      await Future<void>.delayed(Duration.zero);

      expect(events.last.valueOrNull?.name, 'Weekend shop');
      expect(client.streamCalls.single.method, 'watchList');
    });

    test(
      'watch reports a failed seed instead of closing empty',
      () async {
        client.handler = (_, _, _) => throw dto.NotAMemberException();

        final first = await repository.watch(ListId(listUuid.uuid)).first;

        expect(first.failureOrNull, const Failure.unauthorized());
      },
    );
  });
}
