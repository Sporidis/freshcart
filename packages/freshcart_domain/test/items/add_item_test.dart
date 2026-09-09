import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

import '../fakes/builders.dart';
import '../fakes/fake_repositories.dart';

void main() {
  group('AddItem', () {
    late FakeItemRepository items;
    late AddItem addItem;

    setUp(() {
      items = FakeItemRepository();
      items.addResult = Ok(buildItem());
      addItem = AddItem(items);
    });

    test('adds an item with a valid name', () async {
      final result = await addItem(listId: testList, name: 'Milk');

      expect(result.isOk, isTrue);
      expect(items.addCalls.single.name, 'Milk');
      expect(items.addCalls.single.quantity, 1);
    });

    test('trims surrounding whitespace from the name', () async {
      await addItem(listId: testList, name: '  Milk  ');

      expect(items.addCalls.single.name, 'Milk');
    });

    test('rejects a blank name before calling the repository', () async {
      final result = await addItem(listId: testList, name: '   ');

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(items.addCalls, isEmpty);
    });

    test('rejects a name longer than the maximum', () async {
      final result = await addItem(
        listId: testList,
        name: 'x' * (AddItem.maxNameLength + 1),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(items.addCalls, isEmpty);
    });

    test('accepts a name exactly at the maximum', () async {
      final result = await addItem(
        listId: testList,
        name: 'x' * AddItem.maxNameLength,
      );

      expect(result.isOk, isTrue);
    });

    test('rejects a quantity below one', () async {
      final result = await addItem(
        listId: testList,
        name: 'Milk',
        quantity: 0,
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(items.addCalls, isEmpty);
    });

    test('normalises a whitespace-only note to no note at all', () async {
      await addItem(listId: testList, name: 'Milk', noteText: '   ');

      expect(items.addCalls.single.noteText, isNull);
    });

    test('trims a real note', () async {
      await addItem(listId: testList, name: 'Milk', noteText: '  oat one  ');

      expect(items.addCalls.single.noteText, 'oat one');
    });
  });
}
