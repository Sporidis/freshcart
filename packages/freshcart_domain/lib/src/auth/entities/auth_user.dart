import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshcart_domain/src/auth/value_objects/user_id.dart';
import 'package:freshcart_domain/src/core/failure.dart';
import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/shops/value_objects/hex_color.dart';

part 'auth_user.freezed.dart';

/// The signed-in identity.
///
/// FreshCart is anonymous-first: a user gets an [id] on first launch without
/// signing up, and later *links* Google or email to that same [id]. The id
/// never changes on upgrade, which is why no data migration is needed
/// (`docs/decisions.md` #6).
@freezed
abstract class AuthUser with _$AuthUser {
  /// Creates an authenticated user.
  const factory AuthUser({
    required UserId id,
    required String displayName,
    required bool isAnonymous,
    String? email,

    /// A colour the user picked for their own avatar, from the same swatches
    /// shops use ([HexColor]). `null` until they choose one, which is not a
    /// missing state to fix — [avatarPhotoUrl] and [avatarColor] both being
    /// unset is what "use the automatic colour" *means* (`docs/decisions.md`
    /// #65 extends this to a photo).
    HexColor? avatarColor,

    /// A photo the user uploaded for their avatar, or `null` if they have not
    /// set one. Takes priority over [avatarColor] when rendering — chosen
    /// deliberately over automatically, and a photo over a flat colour once
    /// both exist.
    String? avatarPhotoUrl,
  }) = _AuthUser;

  const AuthUser._();

  /// The shortest a display name may be.
  ///
  /// One character is almost always a slip rather than a name, and a shared
  /// list where a member shows as "A" is no more readable than one where they
  /// show as "Someone".
  static const int minDisplayNameLength = 2;

  /// The longest a display name may be.
  static const int maxDisplayNameLength = 40;

  /// Validates a proposed display name, returning it trimmed.
  ///
  /// Trims *before* measuring, so a name of two spaces is rejected rather than
  /// counted as two characters.
  static Result<String> validateDisplayName(String displayName) {
    final trimmed = displayName.trim();
    if (trimmed.length < minDisplayNameLength) {
      return const Err(
        Failure.validation('displayName', 'Please enter your name to continue'),
      );
    }
    if (trimmed.length > maxDisplayNameLength) {
      return const Err(
        Failure.validation('displayName', 'That name is too long'),
      );
    }
    return Ok(trimmed);
  }

  /// Whether this account would survive losing the current device.
  ///
  /// An anonymous session lives only in local storage: lose it and you lose
  /// access to every shared list. The UI uses this to nudge an upgrade at the
  /// moment it matters — creating or joining a shared list.
  bool get isRecoverable => !isAnonymous;

  /// The largest avatar photo accepted, in bytes.
  ///
  /// A generous ceiling for something the client is expected to have already
  /// downsized before it ever reaches here (`docs/decisions.md` #65) — this
  /// exists as a backstop against a client that skipped that step, not as the
  /// size a well-behaved upload is expected to bump up against.
  static const int maxAvatarPhotoBytes = 5 * 1024 * 1024;

  /// Validates a proposed avatar photo.
  ///
  /// Rejects an empty upload (nothing to store) and one over
  /// [maxAvatarPhotoBytes]. Deliberately does not sniff the format — that is
  /// the storage layer's job, not a domain rule.
  static Result<Uint8List> validateAvatarPhoto(Uint8List bytes) {
    if (bytes.isEmpty) {
      return const Err(
        Failure.validation('avatarPhoto', 'That photo looks empty'),
      );
    }
    if (bytes.length > maxAvatarPhotoBytes) {
      return const Err(
        Failure.validation('avatarPhoto', 'That photo is too large'),
      );
    }
    return Ok(bytes);
  }
}
