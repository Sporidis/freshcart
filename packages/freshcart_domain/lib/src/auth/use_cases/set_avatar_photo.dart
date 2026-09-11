import 'dart:typed_data';

import 'package:freshcart_domain/src/auth/entities/auth_user.dart';
import 'package:freshcart_domain/src/auth/ports/auth_port.dart';
import 'package:freshcart_domain/src/core/result.dart';

/// Uploads a photo for the caller's own avatar.
///
/// The one avatar-related write with a real rule behind it — size —, which is
/// why it gets a use case of its own rather than a direct call to
/// [AuthPort.setAvatarPhoto] the way `setAvatarColor` and `clearAvatarPhoto`
/// are called directly from the application layer (mirroring how this
/// codebase already treats `signOut`/`linkGoogle`/`linkEmail`: a trivial
/// forward with nothing to validate does not earn a use-case wrapper).
class SetAvatarPhoto {
  /// Creates the use case against an [AuthPort].
  const SetAvatarPhoto(this._auth);

  final AuthPort _auth;

  /// Validates [bytes] and uploads them.
  Future<Result<AuthUser>> call(Uint8List bytes) async =>
      switch (AuthUser.validateAvatarPhoto(bytes)) {
        Err(:final failure) => Err(failure),
        Ok(:final value) => await _auth.setAvatarPhoto(value),
      };
}
