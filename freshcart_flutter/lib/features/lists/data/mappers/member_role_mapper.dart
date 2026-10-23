import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';

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
