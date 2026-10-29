import 'package:freshcart_domain/freshcart_domain.dart' as domain;
import 'package:freshcart_server/src/common/business/require_valid.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

/// Adds a login method to an EXISTING account.
///
/// This is what decisions.md #6 depends on: users start anonymous, and when
/// they link an email later, they keep the same `authUserId`. So all their
/// lists stay theirs, nothing has to be moved.
///
/// Serverpod 3.4 doesn't support linking out of the box. But
/// `EmailIdpAdmin.createEmailAuthentication` accepts an existing
/// `authUserId`, so we built linking on top of that (decisions.md #39).
abstract final class AccountLinkService {
  /// Adds an email and password to account [authUserId].
  ///
  /// Throws [AccountAlreadyLinkedException] if the account already has an
  /// email. Two emails on one account would be confusing.
  static Future<void> linkEmail(
    Session session,
    UuidValue authUserId, {
    required String email,
    required String password,
  }) async {
    final existing = await EmailAccount.db.findFirstRow(
      session,
      where: (t) => t.authUserId.equals(authUserId),
    );
    if (existing != null) throw AccountAlreadyLinkedException();

    // If this email belongs to another account, refuse. Otherwise you could
    // take over someone else's account.
    final claimed = await EmailAccount.db.findFirstRow(
      session,
      where: (t) => t.email.equals(email.toLowerCase()),
    );
    if (claimed != null) throw EmailAlreadyInUseException();

    // The admin call below skips Serverpod's password check, so the domain
    // rule runs here. It also returns the password normalized, the form
    // every login compares against.
    final validPassword = requireValid(
      domain.AuthUser.validatePassword(password),
    );

    await AuthServices.instance.emailIdp.admin.createEmailAuthentication(
      session,
      authUserId: authUserId,
      email: email,
      password: validPassword,
    );
  }

  /// Which login methods account [authUserId] has.
  ///
  /// None means the account is still anonymous. The app uses this to decide
  /// whether to ask the user to add an email.
  static Future<List<LinkedProvider>> linkedProviders(
    Session session,
    UuidValue authUserId,
  ) async {
    final email = await EmailAccount.db.findFirstRow(
      session,
      where: (t) => t.authUserId.equals(authUserId),
    );
    final google = await GoogleAccount.db.findFirstRow(
      session,
      where: (t) => t.authUserId.equals(authUserId),
    );

    return [
      if (email != null) LinkedProvider.email,
      if (google != null) LinkedProvider.google,
      if (email == null && google == null) LinkedProvider.anonymous,
    ];
  }

  /// Whether account [authUserId] would survive losing the phone (has a
  /// login method).
  static Future<bool> isRecoverable(
    Session session,
    UuidValue authUserId,
  ) async {
    final providers = await linkedProviders(session, authUserId);
    return !providers.contains(LinkedProvider.anonymous);
  }
}
