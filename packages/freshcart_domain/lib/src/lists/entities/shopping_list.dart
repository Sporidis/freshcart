import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshcart_domain/src/auth/value_objects/user_id.dart';
import 'package:freshcart_domain/src/core/failure.dart';
import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/lists/entities/list_member.dart';
import 'package:freshcart_domain/src/lists/value_objects/join_code.dart';
import 'package:freshcart_domain/src/lists/value_objects/list_id.dart';

part 'shopping_list.freezed.dart';

/// A shopping list, shared by one or more people.
///
/// The list contains its members. Items are loaded separately, because
/// there can be hundreds and they change much more often than the list.
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

    /// Whether checked items are removed automatically when everything is
    /// checked (instead of tapping "Clear checked") (decisions.md #79). Off
    /// by default, so existing lists don't suddenly start removing items.
    @Default(false) bool clearCheckedAfterShopping,

    /// True while this list has a change waiting in the offline queue (not
    /// saved on the server yet). Then `id` may be a temporary id. See
    /// `docs/offline-sync-plan.md` §2.
    @Default(false) bool pending,
  }) = _ShoppingList;

  const ShoppingList._();

  /// Maximum list name length.
  static const int maxNameLength = 60;

  /// Checks a list name and returns it without spaces at the ends.
  ///
  /// On the entity (not in `CreateList`), so creating and renaming use the
  /// same rule. Static, because it's needed before the list exists.
  static Result<String> validateName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return const Err(Failure.validation('name', 'Give the list a name'));
    }
    if (trimmed.length > maxNameLength) {
      return const Err(Failure.validation('name', 'That name is too long'));
    }
    return Ok(trimmed);
  }

  /// Whether [userId] is a member of this list.
  bool hasMember(UserId userId) =>
      members.any((member) => member.userId == userId);

  /// The membership record for [userId], or `null` if they are not a member.
  ListMember? memberFor(UserId userId) {
    for (final member in members) {
      if (member.userId == userId) return member;
    }
    return null;
  }

  /// Whether [userId] is the owner (can rename, delete, remove members).
  bool isOwnedBy(UserId userId) => ownerId == userId;
}
