import 'package:freshcart_domain/freshcart_domain.dart' as domain;
import 'package:freshcart_server/src/auth/business/email_message.dart';
import 'package:freshcart_server/src/auth/business/email_sender.dart';
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
      // The domain's rule, so sign-up and reset accept exactly what the app
      // and linkEmail accept. The endpoint has already normalized it.
      passwordValidationFunction: (password) =>
          domain.AuthUser.validatePassword(password).isOk,
      sendRegistrationVerificationCode: sendRegistrationCode,
      sendPasswordResetVerificationCode: sendPasswordResetCode,
    ),
  ];

  /// Sends the login emails (verification and password-reset codes).
  ///
  /// The logging sender until a real one is set in `server.dart`; tests
  /// keep the logging one. Production must not start with the logging one,
  /// because it writes codes to the log.
  static EmailSender emailSender = const LoggingEmailSender();

  // TODO: make the login emails more attractive (branded HTML layout, the
  // code large and easy to copy) and translate them (nl default, en, fr, ru,
  // tl), instead of the plain English one-liners below.

  /// Emails a registration code.
  static Future<void> sendRegistrationCode(
    Session session, {
    required String email,
    required UuidValue accountRequestId,
    required String verificationCode,
    required Transaction? transaction,
  }) => emailSender.send(
    session,
    EmailMessage(
      to: email,
      subject: 'Your FreshCart code',
      body: 'Your code to finish signing up: $verificationCode',
    ),
  );

  /// Emails a password-reset code.
  static Future<void> sendPasswordResetCode(
    Session session, {
    required String email,
    required UuidValue passwordResetRequestId,
    required String verificationCode,
    required Transaction? transaction,
  }) => emailSender.send(
    session,
    EmailMessage(
      to: email,
      subject: 'Reset your FreshCart password',
      body: 'Your code to reset your password: $verificationCode',
    ),
  );
}
