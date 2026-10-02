import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/lists/data/mappers/list_member_mapper.dart';

/// Converts a Serverpod [dto.ShoppingList] into our domain [ShoppingList].
extension ShoppingListDtoX on dto.ShoppingList {
  /// Converts to the domain [ShoppingList].
  ///
  /// Two checks happen here:
  /// - Serverpod's `id` can be null (for rows not saved yet). Ours can't,
  ///   because a list from the server always has an id.
  /// - `joinCode` comes as a plain `String`. We turn it into a [JoinCode],
  ///   which checks it's valid.
  ///
  /// Throws [StateError] if either check fails. That means the server is
  /// broken (a bug), not a normal failure, so it's not a `Result`.
  ShoppingList toDomain() {
    final rawId = id;
    if (rawId == null) {
      throw StateError('Server returned a ShoppingList without an id');
    }
    final parsedCode = JoinCode.parse(joinCode);
    return ShoppingList(
      id: ListId(rawId.uuid),
      name: name,
      joinCode: switch (parsedCode) {
        Ok<JoinCode>(:final value) => value,
        Err<JoinCode>() => throw StateError(
          'Server returned an invalid join code: $joinCode',
        ),
      },
      ownerId: UserId(ownerId.uuid),
      createdAt: createdAt,
      members: (members ?? const []).map((m) => m.toDomain()).toList(),
      clearCheckedAfterShopping: clearCheckedAfterShopping,
    );
  }
}
