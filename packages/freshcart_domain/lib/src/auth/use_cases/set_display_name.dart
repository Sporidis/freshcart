import 'package:freshcart_domain/src/auth/entities/auth_user.dart';
import 'package:freshcart_domain/src/auth/ports/auth_port.dart';
import 'package:freshcart_domain/src/core/result.dart';

/// Sets the name collaborators see next to this user's changes.
///
/// The rule it enforces previously lived in the onboarding wizard's *state
/// class* — an application-layer type — which meant the only screen that
/// checked it was the one that happened to own that state. Any other entry
/// point (a settings screen, a nudge after joining) would have written an
/// unchecked name straight through the port.
class SetDisplayName {
  /// Creates the use case against an [AuthPort].
  const SetDisplayName(this._auth);

  final AuthPort _auth;

  /// Validates [displayName] and stores it.
  Future<Result<AuthUser>> call(String displayName) async =>
      switch (AuthUser.validateDisplayName(displayName)) {
        Err(:final failure) => Err(failure),
        Ok(:final value) => await _auth.setDisplayName(value),
      };
}
