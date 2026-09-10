import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/items/data/mappers/note_mapper.dart';

/// Maps a [dto.ShoppingItem] wire object to the domain entity.
extension ShoppingItemDtoX on dto.ShoppingItem {
  /// Converts to the domain [ShoppingItem].
  ///
  /// Throws [StateError] on a missing id: a persisted item always has one, so
  /// its absence is a broken server contract rather than an expected failure.
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

/// Maps a domain [ShoppingItem] back to the wire object.
extension ShoppingItemX on ShoppingItem {
  /// Converts to a [dto.ShoppingItem] for a write.
  ///
  /// `updatedAt` is carried across deliberately: it is the optimistic-
  /// concurrency token the server compares against the stored row, so dropping
  /// or refreshing it here would silently disable conflict detection.
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
