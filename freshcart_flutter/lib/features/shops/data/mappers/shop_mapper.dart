import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';

/// Maps a [dto.Shop] wire object to the domain entity.
extension ShopDtoX on dto.Shop {
  /// Converts to the domain [Shop].
  ///
  /// The wire carries a bare `int`; the domain wraps it in [HexColor], which
  /// validates the range and knows how to render itself. Note what does *not*
  /// happen here: no Flutter `Color` is constructed. That conversion belongs to
  /// the theme layer, which is what keeps the domain Flutter-free.
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

/// Maps a domain [Shop] back to the wire object.
extension ShopX on Shop {
  /// Converts to a [dto.Shop] for a write.
  dto.Shop toDto() => dto.Shop(
    id: dto.UuidValue.withValidation(id.value),
    listId: dto.UuidValue.withValidation(listId.value),
    name: name,
    colorArgb: color.argb,
    isActive: isActive,
  );
}

/// Maps the domain's disposition onto the wire enum.
///
/// Two enums with the same three names, deliberately: the generated one is a
/// DTO and must not become the domain's vocabulary (golden rule 2). The
/// exhaustive switch means adding a case to either forces this to be updated.
extension ShopItemDispositionX on ShopItemDisposition {
  /// This disposition, as the server names it.
  dto.ShopItemDisposition toDto() => switch (this) {
    ShopItemDisposition.untag => dto.ShopItemDisposition.untag,
    ShopItemDisposition.moveToShop => dto.ShopItemDisposition.moveToShop,
    ShopItemDisposition.deleteItems => dto.ShopItemDisposition.deleteItems,
  };
}
