import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshcart_domain/src/auth/value_objects/user_id.dart';
import 'package:freshcart_domain/src/core/failure.dart';
import 'package:freshcart_domain/src/core/result.dart';
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

    /// Whether checked items clear themselves the moment the whole list is
    /// checked, instead of waiting for an explicit "Clear checked" tap
    /// (decisions #79). Off by default: this changes what happens to items
    /// people have already added, so an existing list does not suddenly
    /// start clearing itself out from under anyone.
    @Default(false) bool clearCheckedAfterShopping,

    /// True while this list reflects a write that couldn't reach the server
    /// and is sitting in the offline queue rather than confirmed there (Flow
    /// 07). `id` may be a locally-minted temp id in that state — see
    /// `docs/offline-sync-plan.md` §2.
    @Default(false) bool pending,
  }) = _ShoppingList;

  const ShoppingList._();

  /// The longest a list name may be.
  static const int maxNameLength = 60;

  /// Validates a proposed list name, returning it trimmed.
  ///
  /// On the entity rather than in `CreateList` because creating and renaming
  /// are two doors into the same field: a name that is illegal to create must
  /// stay illegal to rename to. Static because the rule has to hold before the
  /// list exists.
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
