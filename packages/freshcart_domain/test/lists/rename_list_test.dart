import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

import '../fakes/builders.dart';
import '../fakes/fake_repositories.dart';

void main() {
  group('RenameList', () {
    late FakeListRepository lists;
    late RenameList renameList;

    setUp(() {
      lists = FakeListRepository();
      renameList = RenameList(lists);
    });

    test('renames the list', () async {
      final result = await renameList(testList, 'Camping Trip');

      expect(result.isOk, isTrue);
      expect(lists.renameCalls.single.id, testList);
      expect(lists.renameCalls.single.name, 'Camping Trip');
    });

    test('trims surrounding whitespace from the name', () async {
      await renameList(testList, '  Camping Trip  ');

      expect(lists.renameCalls.single.name, 'Camping Trip');
    });

    // The regression: renaming used to reach the repository unvalidated, so a
    // list could be renamed to something CreateList would never have allowed.
    test('rejects a blank name without calling the repository', () async {
      final result = await renameList(testList, '   ');

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(lists.renameCalls, isEmpty);
    });

    test('rejects a name longer than the maximum', () async {
      final result = await renameList(
        testList,
        'x' * (ShoppingList.maxNameLength + 1),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(lists.renameCalls, isEmpty);
    });

    test('accepts a name of exactly the maximum length', () async {
      final result = await renameList(
        testList,
        'x' * ShoppingList.maxNameLength,
      );

      expect(result.isOk, isTrue);
      expect(lists.renameCalls, hasLength(1));
    });

    test('enforces exactly the rules CreateList enforces', () async {
      // Both doors, one rule.
      lists.createResult = Ok(buildList());
      final createList = CreateList(lists);

      for (final name in ['', '   ', 'x' * (ShoppingList.maxNameLength + 1)]) {
        expect(
          (await createList(name)).failureOrNull,
          isA<ValidationFailure>(),
        );
        expect(
          (await renameList(testList, name)).failureOrNull,
          isA<ValidationFailure>(),
        );
      }
    });

    test('surfaces a repository failure unchanged', () async {
      lists.renameResult = const Err<ShoppingList>(Failure.notFound());

      final result = await renameList(testList, 'Camping Trip');

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });
  });
}
