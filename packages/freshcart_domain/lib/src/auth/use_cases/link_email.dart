import 'package:freshcart_domain/src/auth/entities/auth_user.dart';
import 'package:freshcart_domain/src/auth/ports/auth_repository.dart';
import 'package:freshcart_domain/src/core/result.dart';

/// Adds an email and password to the anonymous account, so the user keeps
/// their lists if they lose their phone.
///
/// The app checks the password with the same rule the server enforces, so
/// a bad one is explained right away instead of after a round trip.
class LinkEmail {
  /// Creates the use case against an [AuthRepository].
  const LinkEmail(this._auth);

  final AuthRepository _auth;

  /// Checks [password] and links [email] with it.
  Future<Result<AuthUser>> call({
    required String email,
    required String password,
  }) async {
    final passwordValidation = AuthUser.validatePassword(password);
    switch (passwordValidation) {
      case Ok():
        return _auth.linkEmail(
          email: email,
          password: passwordValidation.value,
        );
      case Err(:final failure):
        return Result.err(failure);
    }
  }
}
