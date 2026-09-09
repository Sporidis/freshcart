import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/lists/data/mappers/list_member_mapper.dart';

/// Maps a [dto.ShoppingList] wire object to the domain entity.
extension ShoppingListDtoX on dto.ShoppingList {
  /// Converts to the domain [ShoppingList].
  ///
  /// Two things happen here that are the reason mapping exists at all. The
  /// generated `id` is nullable because the wire shape allows an unsaved row;
  /// the domain entity's id is not, because a list that came back from the
  /// server always has one. And `joinCode` arrives as a bare `String` and is
  /// re-parsed into a validated [JoinCode], so a malformed code from a stale
  /// server cannot slip upward unnoticed.
  ///
  /// Throws [StateError] if either invariant is violated — that is a broken
  /// server contract, not an expected failure, so it must not be swallowed
  /// into a `Result`.
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
    );
  }
}
