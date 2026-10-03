import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshcart_domain/src/auth/value_objects/user_id.dart';
import 'package:freshcart_domain/src/lists/entities/member_role.dart';
import 'package:freshcart_domain/src/shops/value_objects/hex_color.dart';

part 'list_member.freezed.dart';

/// One person on a shopping list.
///
/// [displayName], [avatarColor] and [avatarPhotoUrl] are always the
/// member's current profile. The server fills them in on every read, and
/// sends the list again when they change (decisions.md #98). So the app
/// never has to look people up separately.
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
