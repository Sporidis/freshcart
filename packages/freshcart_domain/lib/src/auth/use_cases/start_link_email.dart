import 'package:freshcart_domain/src/auth/entities/auth_user.dart';
import 'package:freshcart_domain/src/auth/ports/auth_repository.dart';
import 'package:freshcart_domain/src/auth/use_cases/link_email.dart';
import 'package:freshcart_domain/src/core/result.dart';

/// Asks the server to email a code to the address being linked.
///
/// The password isn't sent yet, but it is checked here: otherwise the user
/// would wait for a code, type it, and only then hear the password is too
/// short.
class StartLinkEmail {
  /// Creates the use case against an [AuthRepository].
  const StartLinkEmail(this._auth);

  final AuthRepository _auth;

  /// Checks [password], then sends a code to [email]. Returns the request
  /// id that [LinkEmail] needs.
  Future<Result<String>> call({
    required String email,
    required String password,
  }) async => switch (AuthUser.validatePassword(password)) {
    Err(:final failure) => Err(failure),
    Ok() => await _auth.startLinkEmail(email),
  };
}
