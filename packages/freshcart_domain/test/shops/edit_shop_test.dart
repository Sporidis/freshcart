import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

import '../fakes/builders.dart';
import '../fakes/fake_repositories.dart';

void main() {
  group('EditShop', () {
    late FakeShopRepository shops;
    late EditShop editShop;
    final orange = HexColor.fromArgb(0xFFE8791A);

    setUp(() {
      shops = FakeShopRepository();
      editShop = EditShop(shops);
    });

    test('renames the shop', () async {
      final result = await editShop(buildShop(), name: 'Delhaize');

      expect(result.isOk, isTrue);
      expect(shops.savedShops.single.name, 'Delhaize');
    });

    test('recolours the shop, keeping its name', () async {
      await editShop(buildShop(name: 'Albert Heijn'), color: orange);

      expect(shops.savedShops.single.name, 'Albert Heijn');
      expect(shops.savedShops.single.color, orange);
    });

    test('leaves the colour alone when only the name changes', () async {
      final original = buildShop(colorArgb: 0xFF2456A6);

      await editShop(original, name: 'Delhaize');

      expect(shops.savedShops.single.color, original.color);
    });

    test('rejects a blank name without calling the repository', () async {
      final result = await editShop(buildShop(), name: '   ');

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(shops.savedShops, isEmpty);
    });

    test('enforces exactly the rules CreateShop enforces', () async {
      final createShop = CreateShop(shops);
      final blue = HexColor.fromArgb(0xFF2456A6);

      for (final name in ['', '  ', 'x' * (Shop.maxNameLength + 1)]) {
        expect(
          (await createShop(
            listId: testList,
            name: name,
            color: blue,
          )).failureOrNull,
          isA<ValidationFailure>(),
        );
        expect(
          (await editShop(buildShop(), name: name)).failureOrNull,
          isA<ValidationFailure>(),
        );
      }
    });
  });
}
