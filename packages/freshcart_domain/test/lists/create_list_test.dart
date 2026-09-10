import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

import '../fakes/builders.dart';
import '../fakes/fake_repositories.dart';

void main() {
  group('CreateList', () {
    late FakeListRepository lists;
    late CreateList createList;

    setUp(() {
      lists = FakeListRepository();
      lists.createResult = Ok(
        ShoppingList(
          id: testList,
          name: 'Groceries',
          joinCode: JoinCode.parse('ABC234').valueOrNull!,
          ownerId: testUser,
          createdAt: testNow,
        ),
      );
      createList = CreateList(lists);
    });

    test('creates a list with a valid name', () async {
      final result = await createList('Groceries');

      expect(result.isOk, isTrue);
      expect(lists.createCalls.single, 'Groceries');
    });

    test('trims the name before sending it', () async {
      await createList('  Groceries  ');
      expect(lists.createCalls.single, 'Groceries');
    });

    test('rejects a blank name without a round trip', () async {
      final result = await createList('   ');

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(lists.createCalls, isEmpty);
    });

    test('rejects a name past the maximum', () async {
      final result = await createList('x' * (ShoppingList.maxNameLength + 1));

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(lists.createCalls, isEmpty);
    });

    test('accepts a name exactly at the maximum', () async {
      final result = await createList('x' * ShoppingList.maxNameLength);
      expect(result.isOk, isTrue);
    });

    test('passes a repository failure through', () async {
      lists.createResult = const Err(Failure.network('offline'));
      expect(
        (await createList('Groceries')).failureOrNull,
        isA<NetworkFailure>(),
      );
    });
  });
}
