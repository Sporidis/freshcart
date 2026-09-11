import 'dart:typed_data';

import 'package:freshcart_domain/src/auth/entities/auth_user.dart';
import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/shops/value_objects/hex_color.dart';

/// How the domain observes and changes who is signed in.
///
/// Deliberately says nothing about Serverpod, Google or email mechanics: adding
/// a provider later is an implementation swap behind this port, not a rewrite
/// (`docs/decisions.md` #6).
abstract interface class AuthPort {
  /// The current user, or `null` before the first sign-in completes.
  AuthUser? get currentUser;

  /// Emits on every identity change — sign-in, display-name edit, provider
  /// link, sign-out.
  Stream<AuthUser?> authStateChanges();

  /// Creates (or restores) an anonymous identity.
  ///
  /// Called on first launch so a user reaches a working list without a signup
  /// form. The [UserId] it returns is stable for the lifetime of the account,
  /// including after [linkGoogle] or [linkEmail].
  Future<Result<AuthUser>> signInAnonymously();

  /// Sets the name collaborators see next to this user's changes.
  ///
  /// Prompted early on purpose: an anonymous member showing as "Someone" makes
  /// a shared list unreadable.
  Future<Result<AuthUser>> setDisplayName(String displayName);

  /// Sets a colour the user picked for their own avatar.
  ///
  /// Any [HexColor] is accepted — the domain does not restrict this to a
  /// preset swatch list, the same choice already made for a shop's own
  /// colour (`EditShop`); a picker offering only presets is a UI choice, not
  /// a rule this layer enforces.
  Future<Result<AuthUser>> setAvatarColor(HexColor color);

  /// Uploads and sets a photo for the user's avatar, overriding
  /// [AuthUser.avatarColor] wherever an avatar is shown.
  Future<Result<AuthUser>> setAvatarPhoto(Uint8List bytes);

  /// Removes the user's avatar photo, reverting to their stored colour, or
  /// the automatic hash-based one if they never set either.
  Future<Result<AuthUser>> clearAvatarPhoto();

  /// Attaches a Google provider to the *existing* account.
  ///
  /// The user id does not change, so every list and item the anonymous session
  /// created stays attached — that is the whole point of linking rather than
  /// signing in afresh.
  Future<Result<AuthUser>> linkGoogle();

  /// Attaches an email/password provider to the existing account.
  Future<Result<AuthUser>> linkEmail({
    required String email,
    required String password,
  });

  /// Signs out.
  ///
  /// For an anonymous account this is destructive — there is no way back into
  /// that identity — so callers must confirm before invoking it.
  Future<Result<void>> signOut();
}
