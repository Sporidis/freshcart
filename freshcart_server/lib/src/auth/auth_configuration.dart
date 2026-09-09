import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/anonymous.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

/// The identity providers and token managers FreshCart runs with.
///
/// Extracted from `server.dart` so the integration tests can initialise the
/// *same* configuration. `withServerpod` does not run the server's `run()`, so
/// without this the admin APIs used by account linking would throw
/// "AuthServices is not set" in tests while working in production — the worst
/// kind of divergence between the two.
abstract final class AuthConfiguration {
  /// JWT for authentication keys towards the server.
  static List<TokenManagerBuilder> get tokenManagerBuilders => [
    JwtConfigFromPasswords(),
  ];

  /// The providers a user can authenticate with.
  static List<IdentityProviderBuilder> get identityProviderBuilders => [
    // Anonymous-first: users reach a working list without a signup form, and
    // keep the same authUserId when they later link a provider. The default
    // per-IP rate limit is kept — an unauthenticated account-creation endpoint
    // is exactly the sort of thing that gets abused.
    const AnonymousIdpConfig(),
    EmailIdpConfigFromPasswords(
      sendRegistrationVerificationCode: sendRegistrationCode,
      sendPasswordResetVerificationCode: sendPasswordResetCode,
    ),
  ];

  /// Delivers a registration code.
  ///
  /// Logs it for now. Wiring a real mail service is a deployment concern, not
  /// an architectural one.
  static void sendRegistrationCode(
    Session session, {
    required String email,
    required UuidValue accountRequestId,
    required String verificationCode,
    required Transaction? transaction,
  }) {
    session.log('[EmailIdp] Registration code ($email): $verificationCode');
  }

  /// Delivers a password reset code.
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
