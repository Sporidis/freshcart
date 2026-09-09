import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshcart_domain/src/auth/value_objects/user_id.dart';
import 'package:freshcart_domain/src/lists/entities/list_member.dart';
import 'package:freshcart_domain/src/lists/value_objects/join_code.dart';
import 'package:freshcart_domain/src/lists/value_objects/list_id.dart';

part 'shopping_list.freezed.dart';

/// A shopping list shared by one or more people.
///
/// The list owns its membership; items are fetched separately because a list
/// can hold hundreds of them and the two change at very different rates.
@freezed
abstract class ShoppingList with _$ShoppingList {
  /// Creates a shopping list.
  const factory ShoppingList({
    required ListId id,
    required String name,
    required JoinCode joinCode,
    required UserId ownerId,
    required DateTime createdAt,
    @Default(<ListMember>[]) List<ListMember> members,
  }) = _ShoppingList;

  const ShoppingList._();

  /// Whether [userId] currently belongs to this list.
  ///
  /// The router's membership guard asks this before opening a list screen.
  bool hasMember(UserId userId) =>
      members.any((member) => member.userId == userId);

  /// The membership record for [userId], or `null` if they are not a member.
  ListMember? memberFor(UserId userId) {
    for (final member in members) {
      if (member.userId == userId) return member;
    }
    return null;
  }

  /// Whether [userId] may rename or delete this list, or remove members.
  bool isOwnedBy(UserId userId) => ownerId == userId;
}
