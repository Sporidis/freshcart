import 'package:freshcart_server/src/common/business/session_user.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/users/business/profile_service.dart';
import 'package:serverpod/serverpod.dart';

/// The caller's own FreshCart profile.
class ProfileEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// The caller's display name, falling back to a placeholder.
  Future<String> displayName(Session session) =>
      ProfileService.displayNameFor(session, session.requireUserId);

  /// Sets the caller's display name.
  Future<MemberProfile> setDisplayName(Session session, String displayName) =>
      ProfileService.setDisplayName(
        session,
        session.requireUserId,
        displayName,
      );
}
