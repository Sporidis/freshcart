import 'package:freshcart_domain/src/auth/entities/auth_user.dart';
import 'package:freshcart_domain/src/auth/ports/auth_repository.dart';
import 'package:freshcart_domain/src/core/result.dart';

/// Adds an email and password to the anonymous account, so the user keeps
/// their lists if they lose their phone. The last step, after
/// `StartLinkEmail` sent a code.
///
/// The app checks the password with the same rule the server enforces, so
/// a bad one is explained right away instead of after a round trip.
class LinkEmail {
  /// Creates the use case against an [AuthRepository].
  const LinkEmail(this._auth);

  final AuthRepository _auth;

  /// Checks [password], then links the email of [requestId] with it, if
  /// [code] is the one that was emailed.
  Future<Result<AuthUser>> call({
    required String requestId,
    required String code,
    required String password,
  }) async {
    final passwordValidation = AuthUser.validatePassword(password);
    switch (passwordValidation) {
      case Ok():
        return _auth.finishLinkEmail(
          requestId: requestId,
          code: code,
          password: passwordValidation.value,
        );
      case Err(:final failure):
        return Result.err(failure);
    }
  }
}
