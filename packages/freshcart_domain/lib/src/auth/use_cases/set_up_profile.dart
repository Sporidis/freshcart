import 'package:freshcart_domain/src/auth/entities/auth_user.dart';
import 'package:freshcart_domain/src/auth/ports/auth_repository.dart';
import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/shops/value_objects/hex_color.dart';

/// Sets a new user's name, and gives them an avatar colour if they don't
/// have one yet: the colour their avatar showed while they typed, so
/// lists show the same one (decisions.md #111).
///
/// The caller picks [shownColor] (colours are a UI choice); the domain
/// owns the rule of when it's saved.
class SetUpProfile {
  /// Creates the use case against an [AuthRepository].
  const SetUpProfile(this._auth);

  final AuthRepository _auth;

  /// Sets [displayName] (checked by [AuthUser.validateDisplayName]), then
  /// saves [shownColor] if the user has no avatar colour yet.
  Future<Result<AuthUser>> call(
    String displayName, {
    required HexColor shownColor,
  }) async => switch (AuthUser.validateDisplayName(displayName)) {
    Err(:final failure) => Err(failure),
    Ok(value: final name) => switch (await _auth.setDisplayName(name)) {
      Err(:final failure) => Err(failure),
      Ok(value: final named) => Ok(await _withColor(named, shownColor)),
    },
  };

  /// [user] with [shownColor] saved, unless they already have a colour.
  /// Cosmetic: if saving fails, [user] as it was (the name still counts).
  Future<AuthUser> _withColor(AuthUser user, HexColor shownColor) async {
    if (user.avatarColor != null) return user;
    return (await _auth.setAvatarColor(shownColor)).valueOrNull ?? user;
  }
}
