import 'dart:typed_data';

import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Where avatar photos are stored.
///
/// Serverpod's built-in storage (saved in the database, public over HTTP).
/// No external service or passwords needed, unlike S3 or Google Cloud
/// Storage (decisions.md #65).
const String _avatarStorageId = 'public';

/// Reads and saves the user's profile (name, colour, photo).
abstract final class ProfileService {
  /// The name shown when a user hasn't picked one yet.
  ///
  /// Users can be on a list before they pick a name, so the app asks for
  /// one early (a list full of "Someone" isn't helpful).
  static const String fallbackDisplayName = 'Someone';

  /// The biggest avatar photo allowed, in bytes.
  ///
  /// Same as `AuthUser.maxAvatarPhotoBytes` in the app. Checked here too, in
  /// case an app doesn't make the photo smaller first.
  static const int maxAvatarPhotoBytes = 5 * 1024 * 1024;

  static Future<MemberProfile?> _profileFor(
    Session session,
    UuidValue authUserId,
  ) => MemberProfile.db.findFirstRow(
    session,
    where: (t) => t.authUserId.equals(authUserId),
  );

  /// The user's name, or [fallbackDisplayName] if they haven't set one.
  static Future<String> displayNameFor(
    Session session,
    UuidValue authUserId,
  ) async =>
      (await _profileFor(session, authUserId))?.displayName ??
      fallbackDisplayName;

  /// The user's avatar colour, or `null` if they haven't set one.
  static Future<int?> avatarColorArgbFor(
    Session session,
    UuidValue authUserId,
  ) async => (await _profileFor(session, authUserId))?.avatarColorArgb;

  /// The public URL of the user's avatar photo, or `null`.
  static Future<String?> avatarPhotoUrlFor(
    Session session,
    UuidValue authUserId,
  ) async => photoUrlFor(
    session,
    (await _profileFor(session, authUserId))?.avatarPhotoPath,
  );

  /// The profiles of everyone in [authUserIds] (in one query), by user id.
  /// Used to fill in a list's members. People without a profile aren't in
  /// the map.
  static Future<Map<UuidValue, MemberProfile>> profilesFor(
    Session session,
    Set<UuidValue> authUserIds,
  ) async {
    if (authUserIds.isEmpty) return const {};
    final profiles = await MemberProfile.db.find(
      session,
      where: (t) => t.authUserId.inSet(authUserIds),
    );
    return {for (final p in profiles) p.authUserId: p};
  }

  /// The public URL for a stored photo [path], or `null` for no photo.
  ///
  /// Calculated on every read (not stored), and used for both your own
  /// profile and list members.
  static Future<String?> photoUrlFor(Session session, String? path) async {
    if (path == null) return null;
    final url = await session.storage.getPublicUrl(
      storageId: _avatarStorageId,
      path: path,
    );
    return url?.toString();
  }

  /// Creates or updates the user's profile.
  static Future<MemberProfile> setDisplayName(
    Session session,
    UuidValue authUserId,
    String displayName,
  ) async {
    return _upsert(
      session,
      authUserId,
      await _profileFor(session, authUserId),
      (p) => p.copyWith(displayName: displayName),
    );
  }

  /// Sets the user's avatar colour. Any colour is allowed (only showing
  /// preset colours is a choice of the app's UI).
  static Future<MemberProfile> setAvatarColor(
    Session session,
    UuidValue authUserId,
    int avatarColorArgb,
  ) async {
    return _upsert(
      session,
      authUserId,
      await _profileFor(session, authUserId),
      (p) => p.copyWith(avatarColorArgb: avatarColorArgb),
    );
  }

  /// Uploads a new avatar photo, replacing the old one.
  ///
  /// Every upload gets a NEW file path, then the old file is deleted. If we
  /// reused the same path, the URL wouldn't change, and image caches (in
  /// Flutter, browsers) would keep showing the old photo
  /// (decisions.md #98).
  static Future<MemberProfile> setAvatarPhoto(
    Session session,
    UuidValue authUserId,
    ByteData bytes,
  ) async {
    if (bytes.lengthInBytes > maxAvatarPhotoBytes) {
      throw AvatarPhotoTooLargeException();
    }
    final path =
        'avatars/$authUserId-${DateTime.now().microsecondsSinceEpoch}.jpg';
    await session.storage.storeFile(
      storageId: _avatarStorageId,
      path: path,
      byteData: bytes,
    );

    final existing = await _profileFor(session, authUserId);
    final previousPath = existing?.avatarPhotoPath;
    final saved = await _upsert(
      session,
      authUserId,
      existing,
      (p) => p.copyWith(avatarPhotoPath: path),
    );
    // Delete the old file only now, after the profile points to the new one.
    // If something failed before this, the old photo still works.
    if (previousPath != null && previousPath != path) {
      await session.storage.deleteFile(
        storageId: _avatarStorageId,
        path: previousPath,
      );
    }
    return saved;
  }

  /// Removes the user's avatar photo.
  ///
  /// The app then shows their colour (or the automatic one). Nothing else
  /// to do here.
  static Future<MemberProfile?> clearAvatarPhoto(
    Session session,
    UuidValue authUserId,
  ) async {
    final existing = await _profileFor(session, authUserId);
    final path = existing?.avatarPhotoPath;
    if (path == null) return existing;

    await session.storage.deleteFile(storageId: _avatarStorageId, path: path);
    return MemberProfile.db.updateRow(
      session,
      existing!.copyWith(avatarPhotoPath: null),
    );
  }

  /// Applies [change] to [existing], or to a new profile (named
  /// [fallbackDisplayName]) when the user has none yet, and saves it.
  static Future<MemberProfile> _upsert(
    Session session,
    UuidValue authUserId,
    MemberProfile? existing,
    MemberProfile Function(MemberProfile) change,
  ) {
    if (existing != null) {
      return MemberProfile.db.updateRow(session, change(existing));
    }
    return MemberProfile.db.insertRow(
      session,
      change(
        MemberProfile(
          authUserId: authUserId,
          displayName: fallbackDisplayName,
          createdAt: DateTime.now().toUtc(),
        ),
      ),
    );
  }
}
