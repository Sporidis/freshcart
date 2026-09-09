import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

import '../fakes/builders.dart';
import '../fakes/fake_repositories.dart';

void main() {
  group('JoinList', () {
    late FakeListRepository lists;
    late JoinList joinList;

    setUp(() {
      lists = FakeListRepository();
      joinList = JoinList(lists);
    });

    ShoppingList aList() => ShoppingList(
      id: testList,
      name: 'Groceries',
      joinCode: JoinCode.parse('ABC234').valueOrNull!,
      ownerId: testUser,
      createdAt: testNow,
    );

    test('joins the list when the code is valid', () async {
      lists.joinResult = Ok(aList());

      final result = await joinList('abc234');

      expect(result.valueOrNull?.name, 'Groceries');
      expect(lists.joinCalls.single.value, 'ABC234');
    });

    test('rejects a malformed code without touching the network', () async {
      final result = await joinList('nope');

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(
        lists.joinCalls,
        isEmpty,
        reason: 'a malformed code must not cost a round trip',
      );
    });

    test('passes a repository failure through unchanged', () async {
      lists.joinResult = const Err(Failure.notFound());

      final result = await joinList('ABC234');

      expect(result.failureOrNull, const Failure.notFound());
    });
  });
}
