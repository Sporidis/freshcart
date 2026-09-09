import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

import '../fakes/builders.dart';
import '../fakes/fake_repositories.dart';

void main() {
  group('ToggleItemChecked', () {
    late FakeItemRepository items;
    late ToggleItemChecked toggle;
    final checkedAt = DateTime.utc(2026, 9, 9, 18, 30);

    setUp(() {
      items = FakeItemRepository();
      toggle = ToggleItemChecked(items, clock: () => checkedAt);
    });

    test('checking records who checked it and when', () async {
      final result = await toggle(buildItem(), by: testUser);

      final saved = items.savedItems.single;
      expect(saved.isChecked, isTrue);
      expect(saved.checkedBy, testUser);
      expect(saved.checkedAt, checkedAt);
      expect(result.valueOrNull?.isChecked, isTrue);
    });

    test('unchecking clears who checked it and when', () async {
      final alreadyChecked = buildItem(
        isChecked: true,
        checkedBy: testUser,
        checkedAt: testNow,
      );

      await toggle(alreadyChecked, by: testUser);

      final saved = items.savedItems.single;
      expect(saved.isChecked, isFalse);
      expect(saved.checkedBy, isNull);
      expect(saved.checkedAt, isNull);
    });

    test('surfaces a conflict so the caller can roll back', () async {
      items.saveResult = const Err(Failure.conflict());

      final result = await toggle(buildItem(), by: testUser);

      expect(result.failureOrNull, const Failure.conflict());
    });
  });
}
