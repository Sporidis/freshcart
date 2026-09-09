import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Reads and writes the caller's FreshCart profile.
abstract final class ProfileService {
  /// The name shown to collaborators when a profile has not been set yet.
  ///
  /// Anonymous-first means a user reaches a shared list before they have
  /// chosen a name; the UI nudges them to change this early, because a list
  /// full of "Someone" is unreadable.
  static const String fallbackDisplayName = 'Someone';

  /// The caller's display name, or [fallbackDisplayName] if none is set.
  static Future<String> displayNameFor(
    Session session,
    UuidValue authUserId,
  ) async {
    final profile = await MemberProfile.db.findFirstRow(
      session,
      where: (t) => t.authUserId.equals(authUserId),
    );
    return profile?.displayName ?? fallbackDisplayName;
  }

  /// Creates or updates the caller's profile.
  static Future<MemberProfile> setDisplayName(
    Session session,
    UuidValue authUserId,
    String displayName,
  ) async {
    final existing = await MemberProfile.db.findFirstRow(
      session,
      where: (t) => t.authUserId.equals(authUserId),
    );
    if (existing == null) {
      return MemberProfile.db.insertRow(
        session,
        MemberProfile(
          authUserId: authUserId,
          displayName: displayName,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    }
    return MemberProfile.db.updateRow(
      session,
      existing.copyWith(displayName: displayName),
    );
  }
}
