import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshcart_domain/src/auth/value_objects/user_id.dart';
import 'package:freshcart_domain/src/lists/entities/member_role.dart';
import 'package:freshcart_domain/src/shops/value_objects/hex_color.dart';

part 'list_member.freezed.dart';

/// One person's membership of a shopping list.
///
/// [displayName] is denormalised on purpose: a list shows "Mom added milk"
/// without a second lookup, and the name survives even if that account is
/// later upgraded from anonymous to Google. [avatarColor] and
/// [avatarPhotoUrl] follow the exact same reasoning (`docs/decisions.md`
/// #65) — snapshotted at join time, not kept live in sync with a later
/// profile edit, same as [displayName] already is.
@freezed
abstract class ListMember with _$ListMember {
  /// Creates a membership record.
  const factory ListMember({
    required UserId userId,
    required String displayName,
    required MemberRole role,
    required DateTime joinedAt,
    HexColor? avatarColor,
    String? avatarPhotoUrl,
  }) = _ListMember;

  const ListMember._();

  /// Whether this member owns the list.
  bool get isOwner => role == MemberRole.owner;
}
