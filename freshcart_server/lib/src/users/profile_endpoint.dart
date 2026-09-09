import 'package:freshcart_server/src/auth/business/account_link_service.dart';
import 'package:freshcart_server/src/common/business/session_user.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/users/business/profile_service.dart';
import 'package:serverpod/serverpod.dart';

/// The caller's own FreshCart profile.
class ProfileEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Who the caller is.
  ///
  /// The client cannot know its own auth user id any other way — it is minted
  /// server-side — and needs it to render optimistic updates that attribute a
  /// change to the right person.
  Future<CurrentUser> me(Session session) async {
    final userId = session.requireUserId;
    return CurrentUser(
      userId: userId,
      displayName: await ProfileService.displayNameFor(session, userId),
      isAnonymous: !await AccountLinkService.isRecoverable(session, userId),
    );
  }

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
