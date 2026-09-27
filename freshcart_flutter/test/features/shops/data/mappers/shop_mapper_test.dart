import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_flutter/features/shops/data/mappers/shop_mapper.dart';

import '../../../../fakes/dto_builders.dart';

void main() {
  dto.Shop wire({int colorArgb = 0xFF4CAF50}) => dto.Shop(
    id: shopUuid,
    listId: listUuid,
    name: 'Colruyt',
    colorArgb: colorArgb,
  );

  group('ShopDtoX.toDomain', () {
    test('wraps the raw int in a validated HexColor', () {
      final shop = wire().toDomain();

      expect(shop.id.value, shopUuid.uuid);
      expect(shop.listId.value, listUuid.uuid);
      expect(shop.name, 'Colruyt');
      expect(shop.color.toHex(), '#4CAF50');
    });

    test('rejects a shop with no id', () {
      final noId = dto.Shop(listId: listUuid, name: 'X', colorArgb: 0xFF000000);
      expect(noId.toDomain, throwsA(isA<StateError>()));
    });

    test('rejects a colour that does not fit in 32 bits', () {
      expect(() => wire(colorArgb: -1).toDomain(), throwsArgumentError);
    });

    test('carries isActive through, not just its default', () {
      final inactive = dto.Shop(
        id: shopUuid,
        listId: listUuid,
        name: 'Colruyt',
        colorArgb: 0xFF4CAF50,
        isActive: false,
      );
      expect(inactive.toDomain().isActive, isFalse);
    });
  });

  group('ShopX.toDto', () {
    test('round-trips unchanged', () {
      final domain = wire().toDomain();
      expect(domain.toDto().toDomain(), domain);
    });

    test('sends the colour back as a plain int', () {
      expect(wire().toDomain().toDto().colorArgb, 0xFF4CAF50);
    });
  });
}
