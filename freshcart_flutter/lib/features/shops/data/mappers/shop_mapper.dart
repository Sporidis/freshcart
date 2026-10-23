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
