import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshcart_domain/src/auth/value_objects/user_id.dart';
import 'package:freshcart_domain/src/core/failure.dart';
import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/core/validation_issue.dart';
import 'package:freshcart_domain/src/shops/value_objects/hex_color.dart';
import 'package:unorm_dart/unorm_dart.dart';

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

  /// Minimum password length. Length is what makes a password hard to
  /// guess (NIST SP 800-63B: at least 8); no "a digit and a symbol" rules,
  /// they mostly make people reuse or write down passwords.
  static const int minPasswordLength = 8;

  /// Maximum password length. Generous on purpose, so passphrases and
  /// password managers fit; it only stops someone sending a huge "password"
  /// that is expensive to hash.
  static const int maxPasswordLength = 128;

  /// [password] in Unicode NFKC form: the form it's hashed and compared in.
  ///
  /// "é" can be typed as one character or as "e" plus an accent, depending
  /// on the keyboard. They look the same but are different text, so without
  /// this a password set on one phone could fail on another (NIST SP
  /// 800-63B asks for normalizing). Every path that hashes a password must
  /// use it, login included, or users get locked out.
  static String normalizePassword(String password) => nfkc(password);

  /// Checks a new password for an email login, and returns it normalized
  /// ([normalizePassword]): store and hash what this returns.
  ///
  /// The one password rule: the app checks it in the form, the server in
  /// `linkEmail`, and Serverpod's own sign-up and reset use it too. The rules
  /// apply to the normalized form, since that's what is kept.
  ///
  /// Never trimmed: a space someone typed is part of their password, so
  /// trimming would lock them out. Spaces at the ends are refused instead,
  /// because they're almost always a copy-paste accident. Any other
  /// character is allowed, Cyrillic or emoji included.
  static Result<String> validatePassword(String rawPassword) {
    final password = normalizePassword(rawPassword);
    if (password.isEmpty) {
      return const Err(
        Failure.validation(ValidationIssue.missing(ValidatedInput.password)),
      );
    }
    if (password.length < minPasswordLength) {
      return const Err(
        Failure.validation(
          ValidationIssue.tooShort(
            ValidatedInput.password,
            min: minPasswordLength,
          ),
        ),
      );
    }
    if (password.length > maxPasswordLength) {
      return const Err(
        Failure.validation(
          ValidationIssue.tooLong(
            ValidatedInput.password,
            max: maxPasswordLength,
          ),
        ),
      );
    }
    if (password.trim() != password) {
      return const Err(
        Failure.validation(
          ValidationIssue.invalidFormat(ValidatedInput.password),
        ),
      );
    }
    return Ok(password);
  }

  /// Whether the account would survive losing this phone.
  ///
  /// An anonymous account only exists on the phone. Lose the phone, lose all
  /// lists. The UI uses this to ask the user to add an email.
  bool get isRecoverable => !isAnonymous;

  /// The biggest avatar photo allowed, in bytes.
  ///
  /// The app already makes photos smaller before uploading (512px, usually
  /// well under 200 KB). This limit is just a safety net (decisions.md #65).
  /// It must stay well below the server's `maxRequestSize`: the photo
  /// travels as base64 (a third bigger), and a request over that size is
  /// cut off before this rule can give its own, clearer message.
  static const int maxAvatarPhotoBytes = 1024 * 1024;

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
