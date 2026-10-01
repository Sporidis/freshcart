import 'dart:typed_data';

import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// The cloud-storage bucket avatar photos live in.
///
/// Serverpod's own zero-config, database-backed storage, served publicly
/// over plain HTTP by default -- no external service or credentials to
/// manage, which fits this project's "no secrets in the repo" rule better
/// than reaching for S3 or Google Cloud Storage (`docs/decisions.md` #65).
const String _avatarStorageId = 'public';

/// Reads and writes the caller's FreshCart profile.
abstract final class ProfileService {
  /// The name shown to collaborators when a profile has not been set yet.
  ///
  /// Anonymous-first means a user reaches a shared list before they have
  /// chosen a name; the UI nudges them to change this early, because a list
  /// full of "Someone" is unreadable.
  static const String fallbackDisplayName = 'Someone';

  /// The largest avatar photo accepted, in bytes.
  ///
  /// Mirrors `AuthUser.maxAvatarPhotoBytes` on the client -- checked here too
  /// as a backstop against a client that skipped its own downsizing step,
  /// the same defence-in-depth reasoning `suggestNames`' two-character floor
  /// already uses (`docs/decisions.md` #64).
  static const int maxAvatarPhotoBytes = 5 * 1024 * 1024;

  static Future<MemberProfile?> _profileFor(
    Session session,
    UuidValue authUserId,
  ) => MemberProfile.db.findFirstRow(
    session,
    where: (t) => t.authUserId.equals(authUserId),
  );

  /// The caller's display name, or [fallbackDisplayName] if none is set.
  static Future<String> displayNameFor(
    Session session,
    UuidValue authUserId,
  ) async =>
      (await _profileFor(session, authUserId))?.displayName ??
      fallbackDisplayName;

  /// The caller's chosen avatar colour, or `null` if they have not set one.
  static Future<int?> avatarColorArgbFor(
    Session session,
    UuidValue authUserId,
  ) async => (await _profileFor(session, authUserId))?.avatarColorArgb;

  /// The caller's avatar photo, resolved to a public URL, or `null` if they
  /// have not set one.
  static Future<String?> avatarPhotoUrlFor(
    Session session,
    UuidValue authUserId,
  ) async => photoUrlFor(
    session,
    (await _profileFor(session, authUserId))?.avatarPhotoPath,
  );

  /// The profiles of everyone in [authUserIds], keyed by auth user id, in
  /// one query -- what a list's member rows are filled in from. Anyone with
  /// no profile yet is simply missing from the map.
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

  /// The public URL for a stored avatar [path], or `null` for no photo.
  ///
  /// Recomputed on every read rather than stored (see `avatarPhotoPath`'s
  /// own doc comment), so it is one helper both the caller's own profile
  /// and every list's member rows go through.
  static Future<String?> photoUrlFor(Session session, String? path) async {
    if (path == null) return null;
    final url = await session.storage.getPublicUrl(
      storageId: _avatarStorageId,
      path: path,
    );
    return url?.toString();
  }

  /// Creates or updates the caller's profile.
  static Future<MemberProfile> setDisplayName(
    Session session,
    UuidValue authUserId,
    String displayName,
  ) async {
    final existing = await _profileFor(session, authUserId);
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

  /// Sets the caller's avatar colour.
  ///
  /// Not restricted to a preset swatch list here either -- see
  /// [AuthPort.setAvatarColor]'s own note on the client: a picker offering
  /// only presets is a UI choice, not a rule this layer enforces.
  static Future<MemberProfile> setAvatarColor(
    Session session,
    UuidValue authUserId,
    int avatarColorArgb,
  ) async {
    final existing = await _profileFor(session, authUserId);
    if (existing == null) {
      return MemberProfile.db.insertRow(
        session,
        MemberProfile(
          authUserId: authUserId,
          displayName: fallbackDisplayName,
          avatarColorArgb: avatarColorArgb,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    }
    return MemberProfile.db.updateRow(
      session,
      existing.copyWith(avatarColorArgb: avatarColorArgb),
    );
  }

  /// Uploads and sets the caller's avatar photo, replacing any existing one.
  ///
  /// Every upload gets a *new* path, and the previous file is deleted once
  /// the new one is stored. Overwriting one fixed path kept the public URL
  /// identical across uploads, and image caches -- Flutter's `NetworkImage`,
  /// a browser, a CDN -- key on the URL, so everyone kept seeing the old
  /// photo (docs/decisions.md #98).
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
    final saved = existing == null
        ? await MemberProfile.db.insertRow(
            session,
            MemberProfile(
              authUserId: authUserId,
              displayName: fallbackDisplayName,
              avatarPhotoPath: path,
              createdAt: DateTime.now().toUtc(),
            ),
          )
        : await MemberProfile.db.updateRow(
            session,
            existing.copyWith(avatarPhotoPath: path),
          );
    // Only once the row points at the new file: a failure before this line
    // leaves the old photo intact and still referenced, never a dangling one.
    if (previousPath != null && previousPath != path) {
      await session.storage.deleteFile(
        storageId: _avatarStorageId,
        path: previousPath,
      );
    }
    return saved;
  }

  /// Removes the caller's avatar photo, if they have one.
  ///
  /// Reverts them to their stored colour, or the automatic hash-based one if
  /// they never set either -- there is nothing else to clear here, the
  /// client works that fallback out for itself from a `null` photo.
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
}
