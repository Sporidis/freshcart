import 'dart:typed_data';

import 'package:freshcart_domain/src/auth/entities/auth_user.dart';
import 'package:freshcart_domain/src/auth/ports/auth_repository.dart';
import 'package:freshcart_domain/src/core/result.dart';

/// Uploads an avatar photo for the signed-in user.
///
/// A use case because there's a rule to check (the size). Simple calls with
/// nothing to check (`setAvatarColor`, `signOut`...) don't get a use case;
/// the app calls [AuthRepository] directly for those.
class SetAvatarPhoto {
  /// Creates the use case against an [AuthRepository].
  const SetAvatarPhoto(this._auth);

  final AuthRepository _auth;

  /// Checks [bytes] and uploads them.
  Future<Result<AuthUser>> call(Uint8List bytes) async =>
      switch (AuthUser.validateAvatarPhoto(bytes)) {
        Err(:final failure) => Err(failure),
        Ok(:final value) => await _auth.setAvatarPhoto(value),
      };
}
