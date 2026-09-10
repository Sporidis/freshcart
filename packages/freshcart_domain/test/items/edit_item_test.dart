import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

import '../fakes/builders.dart';
import '../fakes/fake_repositories.dart';

void main() {
  group('EditItem', () {
    late FakeItemRepository items;
    late EditItem editItem;

    // Pinned so the note's updatedAt is assertable rather than "roughly now".
    final editedAt = DateTime.utc(2026, 3, 1, 12);

    setUp(() {
      items = FakeItemRepository();
      editItem = EditItem(items, clock: () => editedAt);
    });

    test('saves the edited name and quantity', () async {
      final result = await editItem(
        buildItem(name: 'Milk'),
        name: 'Oat milk',
        quantity: 3,
      );

      expect(result.isOk, isTrue);
      expect(items.savedItems.single.name, 'Oat milk');
      expect(items.savedItems.single.quantity, 3);
    });

    test('trims surrounding whitespace from the name', () async {
      await editItem(buildItem(), name: '  Oat milk  ', quantity: 1);

      expect(items.savedItems.single.name, 'Oat milk');
    });

    // The regression this use case exists for: the edit path used to reach the
    // repository unvalidated, so an item could be renamed to something it
    // could never have been created as.
    test('rejects a blank name without calling the repository', () async {
      final result = await editItem(buildItem(), name: '   ', quantity: 1);

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(items.savedItems, isEmpty);
    });

    test('rejects a name longer than the maximum', () async {
      final result = await editItem(
        buildItem(),
        name: 'x' * (ShoppingItem.maxNameLength + 1),
        quantity: 1,
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(items.savedItems, isEmpty);
    });

    test('accepts a name of exactly the maximum length', () async {
      final result = await editItem(
        buildItem(),
        name: 'x' * ShoppingItem.maxNameLength,
        quantity: 1,
      );

      expect(result.isOk, isTrue);
      expect(items.savedItems, hasLength(1));
    });

    test(
      'rejects a quantity below one without calling the repository',
      () async {
        final result = await editItem(buildItem(), name: 'Milk', quantity: 0);

        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(items.savedItems, isEmpty);
      },
    );

    test('enforces exactly the rules AddItem enforces', () async {
      // Both doors, one rule: anything AddItem rejects, EditItem must reject.
      final addItem = AddItem(items..addResult = Ok(buildItem()));

      for (final (name, quantity) in [('', 1), ('   ', 1), ('Milk', 0)]) {
        final added = await addItem(
          listId: testList,
          name: name,
          quantity: quantity,
        );
        final edited = await editItem(
          buildItem(),
          name: name,
          quantity: quantity,
        );

        expect(added.failureOrNull, isA<ValidationFailure>());
        expect(edited.failureOrNull, isA<ValidationFailure>());
      }
    });

    group('notes', () {
      test('attaches a note, stamping the author and the clock', () async {
        await editItem(
          buildItem(),
          name: 'Milk',
          quantity: 1,
          noteText: 'the blue cap one',
        );

        final note = items.savedItems.single.note;
        expect(note?.text, 'the blue cap one');
        expect(note?.authorId, testUser);
        expect(note?.updatedAt, editedAt);
      });

      test('keeps the original author when editing an existing note', () async {
        final original = Note(
          text: 'old',
          authorId: UserId('someone-else'),
          updatedAt: testNow,
        );

        await editItem(
          buildItem(note: original),
          name: 'Milk',
          quantity: 1,
          noteText: 'new text',
        );

        expect(items.savedItems.single.note?.authorId, UserId('someone-else'));
        expect(items.savedItems.single.note?.updatedAt, editedAt);
      });

      test('clears the note when the text is blank or omitted', () async {
        final withNote = buildItem(
          note: Note(text: 'old', authorId: testUser, updatedAt: testNow),
        );

        await editItem(withNote, name: 'Milk', quantity: 1, noteText: '   ');
        await editItem(withNote, name: 'Milk', quantity: 1);

        expect(items.savedItems, hasLength(2));
        expect(items.savedItems.every((item) => item.note == null), isTrue);
      });
    });

    test('untags the item when no shop is given', () async {
      final tagged = buildItem(shopId: ShopId('shop-1'));

      await editItem(tagged, name: 'Milk', quantity: 1);

      expect(items.savedItems.single.shopId, isNull);
    });

    test('surfaces a conflict from the repository unchanged', () async {
      items.saveResult = const Err<ShoppingItem>(Failure.conflict());

      final result = await editItem(buildItem(), name: 'Milk', quantity: 1);

      expect(result.failureOrNull, isA<ConflictFailure>());
    });
  });
}
