import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

import '../fakes/builders.dart';
import '../fakes/fake_repositories.dart';

void main() {
  group('ToggleShopActive', () {
    late FakeShopRepository shops;
    late ToggleShopActive toggleShopActive;

    setUp(() {
      shops = FakeShopRepository();
      toggleShopActive = ToggleShopActive(shops);
    });

    test('an active shop is saved inactive', () async {
      final shop = buildShop();
      expect(shop.isActive, isTrue);

      final result = await toggleShopActive(shop);

      expect(result.isOk, isTrue);
      expect(shops.savedShops.single.isActive, isFalse);
    });

    test('an inactive shop is saved active again', () async {
      final shop = buildShop().toggleActive();
      expect(shop.isActive, isFalse);

      await toggleShopActive(shop);

      expect(shops.savedShops.single.isActive, isTrue);
    });

    test('nothing but isActive changes', () async {
      final shop = buildShop(name: 'Delhaize', colorArgb: 0xFFC0392B);

      await toggleShopActive(shop);

      final saved = shops.savedShops.single;
      expect(saved.id, shop.id);
      expect(saved.listId, shop.listId);
      expect(saved.name, shop.name);
      expect(saved.color, shop.color);
    });

    test('surfaces a repository failure rather than throwing', () async {
      shops.saveResult = const Err(Failure.unexpected('db down'));

      final result = await toggleShopActive(buildShop());

      expect(result.failureOrNull, isA<UnexpectedFailure>());
    });
  });
}
