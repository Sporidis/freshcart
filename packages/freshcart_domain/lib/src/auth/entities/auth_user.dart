import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshcart_domain/src/auth/value_objects/user_id.dart';
import 'package:freshcart_domain/src/core/failure.dart';
import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/core/validation_issue.dart';
import 'package:freshcart_domain/src/shops/value_objects/hex_color.dart';

part 'auth_user.freezed.dart';

/// The signed-in user.
///
/// Users get an [id] on first launch, without signing up (anonymous). Later
/// they can link Google or email to that same [id]. The id never changes,
/// so none of their data has to be moved (decisions.md #6).
@freezed
abstract class AuthUser with _$AuthUser {
  /// Creates an authenticated user.
  const factory AuthUser({
    required UserId id,
    required String displayName,
    required bool isAnonymous,
    String? email,

    /// The colour the user picked for their avatar, or `null`. If both this
    /// and [avatarPhotoUrl] are null, an automatic colour is used
    /// (decisions.md #65).
    HexColor? avatarColor,

    /// The URL of the user's avatar photo, or `null`. If set, it's shown
    /// instead of [avatarColor].
    String? avatarPhotoUrl,
  }) = _AuthUser;

  const AuthUser._();

  /// Minimum name length. One letter is usually a typo, and "A" on a shared
  /// list doesn't tell anyone who it is.
  static const int minDisplayNameLength = 2;

  /// Maximum name length.
  static const int maxDisplayNameLength = 40;

  /// Checks a name and returns it without spaces at the ends.
  ///
  /// Trims first, then checks the length, so "  " (two spaces) is rejected.
  static Result<String> validateDisplayName(String displayName) {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      return const Err(
        Failure.validation(ValidationIssue.missing(ValidatedInput.displayName)),
      );
    }
    if (trimmed.length < minDisplayNameLength) {
      return const Err(
        Failure.validation(
          ValidationIssue.tooShort(
            ValidatedInput.displayName,
            min: minDisplayNameLength,
          ),
        ),
      );
    }
    if (trimmed.length > maxDisplayNameLength) {
      return const Err(
        Failure.validation(
          ValidationIssue.tooLong(
            ValidatedInput.displayName,
            max: maxDisplayNameLength,
          ),
        ),
      );
    }
    return Ok(trimmed);
  }

  /// Whether the account would survive losing this phone.
  ///
  /// An anonymous account only exists on the phone. Lose the phone, lose all
  /// lists. The UI uses this to ask the user to add an email.
  bool get isRecoverable => !isAnonymous;

  /// The biggest avatar photo allowed, in bytes.
  ///
  /// The app already makes photos smaller before uploading. This limit is
  /// just a safety net (decisions.md #65).
  static const int maxAvatarPhotoBytes = 5 * 1024 * 1024;

  /// Checks an avatar photo: not empty, and not bigger than
  /// [maxAvatarPhotoBytes]. Doesn't check the file type; that's done where
  /// it's stored.
  static Result<Uint8List> validateAvatarPhoto(Uint8List bytes) {
    if (bytes.isEmpty) {
      return const Err(
        Failure.validation(ValidationIssue.missing(ValidatedInput.avatarPhoto)),
      );
    }
    if (bytes.length > maxAvatarPhotoBytes) {
      return const Err(
        Failure.validation(
          ValidationIssue.tooLarge(
            ValidatedInput.avatarPhoto,
            maxBytes: maxAvatarPhotoBytes,
          ),
        ),
      );
    }
    return Ok(bytes);
  }
}
