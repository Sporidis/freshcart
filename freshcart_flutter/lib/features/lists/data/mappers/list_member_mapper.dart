import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';

/// Maps a [dto.ListMember] wire object to the domain entity.
extension ListMemberDtoX on dto.ListMember {
  /// Converts to the domain [ListMember].
  ListMember toDomain() => ListMember(
    userId: UserId(userId.uuid),
    displayName: displayName,
    role: role.toDomain(),
    joinedAt: joinedAt,
    avatarColor: avatarColorArgb == null
        ? null
        : HexColor.fromArgb(avatarColorArgb!),
    avatarPhotoUrl: avatarPhotoUrl,
  );
}

/// Maps the wire enum to the domain enum.
extension MemberRoleDtoX on dto.MemberRole {
  /// Converts to the domain [MemberRole].
  ///
  /// Written as an exhaustive switch rather than an index lookup so that adding
  /// a role on the server becomes a compile error here instead of a silent
  /// mis-mapping.
  MemberRole toDomain() => switch (this) {
    dto.MemberRole.owner => MemberRole.owner,
    dto.MemberRole.member => MemberRole.member,
  };
}

/// Maps the domain enum back to the wire enum.
extension MemberRoleX on MemberRole {
  /// Converts to the wire [dto.MemberRole].
  dto.MemberRole toDto() => switch (this) {
    MemberRole.owner => dto.MemberRole.owner,
    MemberRole.member => dto.MemberRole.member,
  };
}
