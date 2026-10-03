import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/items/data/mappers/note_mapper.dart';

/// Converts a Serverpod [dto.ShoppingItem] into our domain [ShoppingItem].
extension ShoppingItemDtoX on dto.ShoppingItem {
  /// Converts to the domain [ShoppingItem].
  ///
  /// Throws [StateError] if the id is missing. Items from the server always
  /// have one, so a missing id means a server bug, not a normal failure.
  ShoppingItem toDomain() {
    final rawId = id;
    if (rawId == null) {
      throw StateError('Server returned a ShoppingItem without an id');
    }
    return ShoppingItem(
      id: ItemId(rawId.uuid),
      listId: ListId(listId.uuid),
      name: name,
      addedBy: UserId(addedBy.uuid),
      createdAt: createdAt,
      updatedAt: updatedAt,
      quantity: quantity,
      isChecked: isChecked,
      sortOrder: sortOrder,
      shopId: shopId == null ? null : ShopId(shopId!.uuid),
      note: note?.toDomain(),
      checkedBy: checkedBy == null ? null : UserId(checkedBy!.uuid),
      checkedAt: checkedAt,
    );
  }
}

/// Converts a domain [ShoppingItem] back into a Serverpod [dto.ShoppingItem].
extension ShoppingItemX on ShoppingItem {
  /// Converts to a [dto.ShoppingItem], to send to the server.
  ///
  /// Keep `updatedAt` exactly as it is! The server compares it with its own
  /// copy to see if someone else changed the item in the meantime (a
  /// conflict). Changing it here would break that check.
  dto.ShoppingItem toDto() => dto.ShoppingItem(
    id: dto.UuidValue.withValidation(id.value),
    listId: dto.UuidValue.withValidation(listId.value),
    name: name,
    quantity: quantity,
    isChecked: isChecked,
    sortOrder: sortOrder,
    shopId: shopId == null ? null : dto.UuidValue.withValidation(shopId!.value),
    note: note?.toDto(),
    addedBy: dto.UuidValue.withValidation(addedBy.value),
    checkedBy: checkedBy == null
        ? null
        : dto.UuidValue.withValidation(checkedBy!.value),
    checkedAt: checkedAt,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
