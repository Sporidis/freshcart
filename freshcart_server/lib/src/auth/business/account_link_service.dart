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
  /// Adds the email proven by [registrationToken] to account [authUserId],
  /// with [password].
  ///
  /// The app gets the token from Serverpod's own `startRegistration` and
  /// `verifyRegistrationCode`, so the user has proven they read that inbox.
  /// Those also hide whether an email is already registered (no account
  /// enumeration), so this never says "email in use" either.
  ///
  /// Serverpod 3.4 can only finish a registration as a NEW user, so this
  /// lets it, then merges that user into [authUserId]: the same steps as
  /// Serverpod 4.0's `accountMerger.merge` for email (security-plan 2.2).
  /// On 4.0, replace the merge with that call.
  ///
  /// Throws [AccountAlreadyLinkedException] if the account already has an
  /// email. Two emails on one account would be confusing.
  static Future<void> finishLinkEmail(
    Session session,
    UuidValue authUserId, {
    required String registrationToken,
    required String password,
  }) async {
    final existing = await EmailAccount.db.findFirstRow(
      session,
      where: (t) => t.authUserId.equals(authUserId),
    );
    if (existing != null) throw AccountAlreadyLinkedException();

    // Returned normalized, the form every login compares against.
    final validPassword = requireValid(
      domain.AuthUser.validatePassword(password),
    );

    // One transaction: a failure anywhere leaves no half-linked account
    // and no stray user.
    await session.db.transaction((transaction) async {
      // Checks the token (expiry, attempts, one use) and creates a new user
      // with the email account. Wrapped like Serverpod's own endpoint, so a
      // bad token reaches the app without details.
      final created = await EmailIdpUtils.withReplacedServerEmailException(
        () => AuthServices.instance.emailIdp.utils.accountCreation
            .completeAccountCreation(
              session,
              completeAccountCreationToken: registrationToken,
              password: validPassword,
              transaction: transaction,
            ),
      );

      await _merge(
        session,
        userToKeepId: authUserId,
        userToRemoveId: created.authUserId,
        transaction: transaction,
      );
    });
  }

  /// Moves the email account of [userToRemoveId] to [userToKeepId], then
  /// deletes [userToRemoveId].
  ///
  /// The same steps and names as Serverpod 4.0's `accountMerger.merge` for
  /// email, so upgrading replaces this with that call. The order matters:
  /// deleting first would cascade-delete the email account with the user.
  static Future<void> _merge(
    Session session, {
    required UuidValue userToKeepId,
    required UuidValue userToRemoveId,
    required Transaction transaction,
  }) async {
    await EmailAccount.db.updateWhere(
      session,
      where: (t) => t.authUserId.equals(userToRemoveId),
      columnValues: (t) => [t.authUserId(userToKeepId)],
      transaction: transaction,
    );
    await AuthServices.instance.authUsers.delete(
      session,
      authUserId: userToRemoveId,
      transaction: transaction,
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
