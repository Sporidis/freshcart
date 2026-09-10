import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

import '../fakes/builders.dart';
import '../fakes/fake_repositories.dart';

void main() {
  group('CreateShop', () {
    late FakeShopRepository shops;
    late CreateShop createShop;
    final blue = HexColor.fromArgb(0xFF2456A6);

    setUp(() {
      shops = FakeShopRepository();
      createShop = CreateShop(shops);
    });

    test('creates the shop with its colour', () async {
      final result = await createShop(
        listId: testList,
        name: 'Colruyt',
        color: blue,
      );

      expect(result.isOk, isTrue);
      expect(shops.createCalls.single.name, 'Colruyt');
      expect(shops.createCalls.single.color, blue);
      expect(shops.createCalls.single.listId, testList);
    });

    test('trims surrounding whitespace from the name', () async {
      await createShop(listId: testList, name: '  Colruyt  ', color: blue);

      expect(shops.createCalls.single.name, 'Colruyt');
    });

    test('rejects a blank name without calling the repository', () async {
      final result = await createShop(
        listId: testList,
        name: '   ',
        color: blue,
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(shops.createCalls, isEmpty);
    });

    test('rejects a name too long for a tab pill', () async {
      final result = await createShop(
        listId: testList,
        name: 'x' * (Shop.maxNameLength + 1),
        color: blue,
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(shops.createCalls, isEmpty);
    });
  });
}
