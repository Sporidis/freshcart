import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';

/// Converts a Serverpod [dto.ListMember] into our domain [ListMember].
extension ListMemberDtoX on dto.ListMember {
  /// Converts to the domain [ListMember].
  ListMember toDomain() => ListMember(
    userId: UserId(userId.uuid),
    // The server always sends this. It's only nullable in the Serverpod
    // type for database reasons. If it's missing, use "" (shown as "?").
    displayName: displayName ?? '',
    role: role.toDomain(),
    joinedAt: joinedAt,
    avatarColor: avatarColorArgb == null
        ? null
        : HexColor.fromArgb(avatarColorArgb!),
    avatarPhotoUrl: avatarPhotoUrl,
  );
}

/// Converts Serverpod's role enum into ours.
extension MemberRoleDtoX on dto.MemberRole {
  /// Converts to the domain [MemberRole].
  ///
  /// A `switch` (not an index lookup), so a new role on the server causes a
  /// compile error here, instead of a silent wrong result.
  MemberRole toDomain() => switch (this) {
    dto.MemberRole.owner => MemberRole.owner,
    dto.MemberRole.member => MemberRole.member,
  };
}

/// Converts our role enum back into Serverpod's.
extension MemberRoleX on MemberRole {
  /// Converts to Serverpod's [dto.MemberRole].
  dto.MemberRole toDto() => switch (this) {
    MemberRole.owner => dto.MemberRole.owner,
    MemberRole.member => dto.MemberRole.member,
  };
}
