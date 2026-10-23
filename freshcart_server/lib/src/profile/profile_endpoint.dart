import 'dart:typed_data';

import 'package:freshcart_server/src/auth/business/account_link_service.dart';
import 'package:freshcart_server/src/common/business/session_user.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/lists/business/list_service.dart';
import 'package:freshcart_server/src/profile/business/profile_service.dart';
import 'package:serverpod/serverpod.dart';

/// Endpoint for the user's own profile.
class ProfileEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Who the caller is.
  ///
  /// The app can't know its own user id otherwise (the server creates it).
  /// It needs it to show "you checked this" before the server answers.
  Future<CurrentUser> me(Session session) async {
    final userId = session.requireUserId;
    return CurrentUser(
      userId: userId,
      displayName: await ProfileService.displayNameFor(session, userId),
      avatarColorArgb: await ProfileService.avatarColorArgbFor(
        session,
        userId,
      ),
      avatarPhotoUrl: await ProfileService.avatarPhotoUrlFor(
        session,
        userId,
      ),
      isAnonymous: !await AccountLinkService.isRecoverable(session, userId),
    );
  }

  /// The caller's name, or a placeholder if not set.
  Future<String> displayName(Session session) =>
      ProfileService.displayNameFor(session, session.requireUserId);

  /// Sets the caller's display name.
  Future<MemberProfile> setDisplayName(
    Session session,
    String displayName,
  ) => _thenAnnounce(
    session,
    ProfileService.setDisplayName(session, session.requireUserId, displayName),
  );

  /// Sets the caller's avatar colour.
  Future<MemberProfile> setAvatarColor(Session session, int avatarColorArgb) =>
      _thenAnnounce(
        session,
        ProfileService.setAvatarColor(
          session,
          session.requireUserId,
          avatarColorArgb,
        ),
      );

  /// Uploads the caller's avatar photo.
  Future<MemberProfile> setAvatarPhoto(Session session, ByteData bytes) =>
      _thenAnnounce(
        session,
        ProfileService.setAvatarPhoto(session, session.requireUserId, bytes),
      );

  /// Removes the caller's avatar photo.
  Future<MemberProfile?> clearAvatarPhoto(Session session) => _thenAnnounce(
    session,
    ProfileService.clearAvatarPhoto(session, session.requireUserId),
  );

  /// Waits for a profile change [write], then sends all the caller's lists
  /// again, so others see the new name/avatar right away.
  ///
  /// Done here, not in [ProfileService], because profiles don't know about
  /// lists.
  Future<T> _thenAnnounce<T>(Session session, Future<T> write) async {
    final result = await write;
    await ListService.announceMemberChanged(session, session.requireUserId);
    return result;
  }
}
