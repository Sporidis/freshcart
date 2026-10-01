import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshcart_domain/src/auth/value_objects/user_id.dart';
import 'package:freshcart_domain/src/lists/entities/member_role.dart';
import 'package:freshcart_domain/src/shops/value_objects/hex_color.dart';

part 'list_member.freezed.dart';

/// One person's membership of a shopping list.
///
/// [displayName], [avatarColor] and [avatarPhotoUrl] carry the member's
/// profile *as it is now*: the server fills them in live on every read and
/// re-broadcasts the list when any of them change (`docs/decisions.md` #98),
/// so a list shows "Mom added milk" with Mom's current name and photo,
/// without the client looking her up separately.
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
