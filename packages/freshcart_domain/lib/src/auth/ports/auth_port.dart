import 'dart:typed_data';

import 'package:freshcart_domain/src/auth/entities/auth_user.dart';
import 'package:freshcart_domain/src/auth/entities/sign_in.dart';
import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/shops/value_objects/hex_color.dart';

/// The interface for everything about the signed-in user.
///
/// Doesn't mention Serverpod, Google or email details. Adding a new login
/// method later only changes the implementation, not this interface
/// (decisions.md #6).
abstract interface class AuthPort {
  /// The current user, or `null` before the first sign-in completes.
  AuthUser? get currentUser;

  /// Sends the user again on every change: sign-in, name change, linking an
  /// email, sign-out.
  Stream<AuthUser?> authStateChanges();

  /// Makes sure someone is signed in: restores the saved session, or
  /// creates an anonymous account (so there's no signup form), and says
  /// which. The [UserId] never changes, also not after [linkGoogle] or
  /// [linkEmail].
  Future<Result<SignIn>> ensureSignedIn();

  /// Sets the name others see next to this user's changes.
  ///
  /// Asked early (in onboarding), because "Someone" everywhere on a shared
  /// list isn't helpful.
  Future<Result<AuthUser>> setDisplayName(String displayName);

  /// Sets the user's avatar colour.
  ///
  /// Any [HexColor] is allowed here. Only showing preset colours is a UI
  /// choice, not a domain rule (same as for shops).
  Future<Result<AuthUser>> setAvatarColor(HexColor color);

  /// Uploads an avatar photo. It's shown instead of [AuthUser.avatarColor].
  Future<Result<AuthUser>> setAvatarPhoto(Uint8List bytes);

  /// Removes the avatar photo. Then their chosen colour is shown (or the
  /// automatic one).
  Future<Result<AuthUser>> clearAvatarPhoto();

  /// Links a Google account to the current account.
  ///
  /// The user id stays the same, so all their lists and items stay theirs.
  /// That's why we link instead of making a new account.
  Future<Result<AuthUser>> linkGoogle();

  /// Links an email and password to the current account.
  Future<Result<AuthUser>> linkEmail({
    required String email,
    required String password,
  });

  /// Signs out.
  ///
  /// For an anonymous account this can't be undone (there's no way to sign
  /// back in), so always ask the user first.
  Future<Result<void>> signOut();
}
