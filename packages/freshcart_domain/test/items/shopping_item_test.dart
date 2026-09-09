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
