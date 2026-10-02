import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/anonymous.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

/// The login setup (identity providers and token managers).
///
/// In its own file so the integration tests use the exact same setup. Tests
/// don't run `server.dart`'s `run()`, and without this the account linking
/// code would fail in tests ("AuthServices is not set") but work in
/// production.
abstract final class AuthConfiguration {
  /// Uses JWT for login keys.
  static List<TokenManagerBuilder> get tokenManagerBuilders => [
    JwtConfigFromPasswords(),
  ];

  /// The ways a user can log in.
  static List<IdentityProviderBuilder> get identityProviderBuilders => [
    // Anonymous login, so there's no signup form. The default limit per IP
    // address is kept, because anyone can call this without logging in, so
    // it could be abused to create lots of accounts.
    const AnonymousIdpConfig(),
    EmailIdpConfigFromPasswords(
      sendRegistrationVerificationCode: sendRegistrationCode,
      sendPasswordResetVerificationCode: sendPasswordResetCode,
    ),
  ];

  /// Sends a registration code.
  ///
  /// For now it's only logged. A real email service can be added when
  /// deploying.
  static void sendRegistrationCode(
    Session session, {
    required String email,
    required UuidValue accountRequestId,
    required String verificationCode,
    required Transaction? transaction,
  }) {
    session.log('[EmailIdp] Registration code ($email): $verificationCode');
  }

  /// Sends a password reset code (only logged for now).
  static void sendPasswordResetCode(
    Session session, {
    required String email,
    required UuidValue passwordResetRequestId,
    required String verificationCode,
    required Transaction? transaction,
  }) {
    session.log('[EmailIdp] Password reset code ($email): $verificationCode');
  }
}
