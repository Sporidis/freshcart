import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

import '../fakes/builders.dart';

void main() {
  group('ShoppingItem.matchesShopFilter', () {
    final colruyt = ShopId('shop-colruyt');
    final bakery = ShopId('shop-bakery');

    test('a null filter matches everything', () {
      expect(buildItem(shopId: colruyt).matchesShopFilter(null), isTrue);
      expect(buildItem().matchesShopFilter(null), isTrue);
    });

    test('an untagged item matches every filter', () {
      // Deliberate: a forgotten tag must never hide an item from the shopper.
      expect(buildItem().matchesShopFilter(colruyt), isTrue);
    });

    test('a tagged item matches only its own shop', () {
      final item = buildItem(shopId: colruyt);
      expect(item.matchesShopFilter(colruyt), isTrue);
      expect(item.matchesShopFilter(bakery), isFalse);
    });
  });

  group('ShoppingItem.toggleChecked', () {
    test('is its own inverse', () {
      final item = buildItem();
      final there = item.toggleChecked(by: testUser, at: testNow);
      final back = there.toggleChecked(by: testUser, at: testNow);
      expect(back, item);
    });
  });

  group('ShoppingItem.sortOrderBetween', () {
    test('is 0 for the first item on an empty list', () {
      expect(ShoppingItem.sortOrderBetween(null, null), 0);
    });

    test('sits below the sole item when dropped at the top', () {
      final only = buildItem(sortOrder: 10);
      expect(
        ShoppingItem.sortOrderBetween(null, only),
        10 - ShoppingItem.sortOrderGap,
      );
    });

    test('sits above the sole item when dropped at the bottom', () {
      final only = buildItem(sortOrder: 10);
      expect(
        ShoppingItem.sortOrderBetween(only, null),
        10 + ShoppingItem.sortOrderGap,
      );
    });

    test('is the midpoint when dropped between two items', () {
      final above = buildItem(sortOrder: 10);
      final below = buildItem(sortOrder: 20);
      expect(ShoppingItem.sortOrderBetween(above, below), 15);
    });
  });

  group('ShoppingItem.sameProduct', () {
    test('matches names trimmed', () {
      expect(
        ShoppingItem.sameProduct(
          nameA: 'Milk',
          noteTextA: null,
          nameB: '  Milk  ',
          noteTextB: null,
        ),
        isTrue,
      );
    });

    test('is case-sensitive on the name', () {
      expect(
        ShoppingItem.sameProduct(
          nameA: 'Milk',
          noteTextA: null,
          nameB: 'milk',
          noteTextB: null,
        ),
        isFalse,
      );
    });

    test('a blank note matches an absent one', () {
      expect(
        ShoppingItem.sameProduct(
          nameA: 'Milk',
          noteTextA: '   ',
          nameB: 'Milk',
          noteTextB: null,
        ),
        isTrue,
      );
    });

    test('matches note text regardless of who wrote it or when', () {
      // sameProduct only ever sees plain text -- these are passed as
      // note?.text, never a whole Note -- so this pins that the comparison
      // really is text-only, not incidentally relying on Note's own
      // field-by-field equality (which would fail here on authorId/updatedAt
      // alone).
      expect(
        ShoppingItem.sameProduct(
          nameA: 'Olive oil',
          noteTextA: 'the green tin',
          nameB: 'Olive oil',
          noteTextB: 'the green tin',
        ),
        isTrue,
      );
    });

    test('does not match differing note text', () {
      expect(
        ShoppingItem.sameProduct(
          nameA: 'Olive oil',
          noteTextA: 'the green tin',
          nameB: 'Olive oil',
          noteTextB: 'the blue tin',
        ),
        isFalse,
      );
    });

    test('a real note does not match no note', () {
      expect(
        ShoppingItem.sameProduct(
          nameA: 'Olive oil',
          noteTextA: 'the green tin',
          nameB: 'Olive oil',
          noteTextB: null,
        ),
        isFalse,
      );
    });
  });

  group('ShoppingItem.hasNote', () {
    test('is false for no note and for a blank one', () {
      expect(buildItem().hasNote, isFalse);
      expect(
        buildItem(
          note: Note(text: '   ', authorId: testUser, updatedAt: testNow),
        ).hasNote,
        isFalse,
      );
    });

    test('is true for a real note', () {
      expect(
        buildItem(
          note: Note(text: 'oat one', authorId: testUser, updatedAt: testNow),
        ).hasNote,
        isTrue,
      );
    });
  });
}
