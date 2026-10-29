import 'package:freshcart_domain/freshcart_domain.dart' as domain;
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

/// Endpoint for email login. Extending [EmailIdpBaseEndpoint] is enough to
/// make it available.
///
/// The methods that take a password are overridden only to normalize it
/// (`AuthUser.normalizePassword`) before Serverpod hashes or compares it.
/// `linkEmail` stores passwords normalized, so every path has to: a login
/// that skipped this would fail for someone whose keyboard types "é"
/// differently from the one they signed up on.
class EmailIdpEndpoint extends EmailIdpBaseEndpoint {
  /// {@macro email_account_base_endpoint.login}
  @override
  Future<AuthSuccess> login(
    Session session, {
    required String email,
    required String password,
  }) => super.login(
    session,
    email: email,
    password: domain.AuthUser.normalizePassword(password),
  );

  /// {@macro email_account_base_endpoint.finish_registration}
  @override
  Future<AuthSuccess> finishRegistration(
    Session session, {
    required String registrationToken,
    required String password,
  }) => super.finishRegistration(
    session,
    registrationToken: registrationToken,
    password: domain.AuthUser.normalizePassword(password),
  );

  /// {@macro email_account_base_endpoint.finish_password_reset}
  @override
  Future<void> finishPasswordReset(
    Session session, {
    required String finishPasswordResetToken,
    required String newPassword,
  }) => super.finishPasswordReset(
    session,
    finishPasswordResetToken: finishPasswordResetToken,
    newPassword: domain.AuthUser.normalizePassword(newPassword),
  );
}
