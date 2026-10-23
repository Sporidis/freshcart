import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/lists/data/mappers/member_role_mapper.dart';

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
