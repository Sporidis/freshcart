import 'package:freshcart_domain/src/auth/entities/auth_user.dart';
import 'package:freshcart_domain/src/auth/ports/auth_port.dart';
import 'package:freshcart_domain/src/core/result.dart';

/// Sets the name others see next to this user's changes.
///
/// The name check lives here (in the domain), so every screen that changes
/// the name (onboarding, edit profile...) checks it the same way.
class SetDisplayName {
  /// Creates the use case against an [AuthPort].
  const SetDisplayName(this._auth);

  final AuthPort _auth;

  /// Checks [displayName] and saves it.
  Future<Result<AuthUser>> call(String displayName) async =>
      switch (AuthUser.validateDisplayName(displayName)) {
        Err(:final failure) => Err(failure),
        Ok(:final value) => await _auth.setDisplayName(value),
      };
}
