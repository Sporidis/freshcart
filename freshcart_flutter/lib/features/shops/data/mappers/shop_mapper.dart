import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';

/// Converts a Serverpod [dto.Shop] into our domain [Shop].
extension ShopDtoX on dto.Shop {
  /// Converts to the domain [Shop].
  ///
  /// The server sends the colour as an `int`. We wrap it in [HexColor]
  /// (not a Flutter `Color`), because the domain can't use Flutter.
  Shop toDomain() {
    final rawId = id;
    if (rawId == null) {
      throw StateError('Server returned a Shop without an id');
    }
    return Shop(
      id: ShopId(rawId.uuid),
      listId: ListId(listId.uuid),
      name: name,
      color: HexColor.fromArgb(colorArgb),
      isActive: isActive,
    );
  }
}

/// Converts a domain [Shop] back into a Serverpod [dto.Shop].
extension ShopX on Shop {
  /// Converts to a [dto.Shop], to send to the server.
  dto.Shop toDto() => dto.Shop(
    id: dto.UuidValue.withValidation(id.value),
    listId: dto.UuidValue.withValidation(listId.value),
    name: name,
    colorArgb: color.argb,
    isActive: isActive,
  );
}

/// Converts our domain enum into Serverpod's enum.
///
/// The two enums have the same values on purpose. Serverpod types must
/// never be used in the domain (golden rule 2), so we keep our own copy.
/// If either enum gets a new value, this `switch` won't compile until it's
/// handled.
extension ShopItemDispositionX on ShopItemDisposition {
  /// The matching Serverpod value.
  dto.ShopItemDisposition toDto() => switch (this) {
    ShopItemDisposition.untag => dto.ShopItemDisposition.untag,
    ShopItemDisposition.moveToShop => dto.ShopItemDisposition.moveToShop,
    ShopItemDisposition.deleteItems => dto.ShopItemDisposition.deleteItems,
  };
}
