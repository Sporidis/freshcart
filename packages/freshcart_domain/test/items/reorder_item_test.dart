import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

import '../fakes/builders.dart';
import '../fakes/fake_repositories.dart';

void main() {
  group('ReorderItem', () {
    late FakeItemRepository items;
    late ReorderItem reorderItem;

    setUp(() {
      items = FakeItemRepository();
      reorderItem = ReorderItem(items);
    });

    test('saves the item at the midpoint of its new neighbours', () async {
      final item = buildItem(sortOrder: 100);
      final before = buildItem(id: 'b', sortOrder: 10);
      final after = buildItem(id: 'a', sortOrder: 20);

      final result = await reorderItem(item, before: before, after: after);

      expect(result.isOk, isTrue);
      expect(items.savedItems.single.sortOrder, 15);
    });

    test('drops past the last item when moved to the bottom', () async {
      final item = buildItem(sortOrder: 100);
      final last = buildItem(id: 'l', sortOrder: 20);

      await reorderItem(item, before: last, after: null);

      expect(
        items.savedItems.single.sortOrder,
        20 + ShoppingItem.sortOrderGap,
      );
    });

    test('surfaces a conflict from the repository unchanged', () async {
      items.saveResult = const Err(Failure.conflict());

      final result = await reorderItem(buildItem(), before: null, after: null);

      expect(result, const Err<ShoppingItem>(Failure.conflict()));
    });
  });
}
