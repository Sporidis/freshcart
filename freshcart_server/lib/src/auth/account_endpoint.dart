import 'package:freshcart_server/src/auth/business/account_deletion_service.dart';
import 'package:freshcart_server/src/auth/business/account_link_service.dart';
import 'package:freshcart_server/src/common/business/session_user.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Endpoint for the caller's account: adding a login (email) to an
/// anonymous account, and deleting the account.
class AccountEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Which login methods the caller's account has.
  Future<List<LinkedProvider>> linkedProviders(Session session) =>
      AccountLinkService.linkedProviders(session, session.requireUserId);

  /// Adds a verified email and a password to the caller's account.
  ///
  /// [registrationToken] comes from `emailIdp.startRegistration` and
  /// `emailIdp.verifyRegistrationCode`. The `authUserId` stays the same, so
  /// all their lists stay theirs.
  Future<List<LinkedProvider>> finishLinkEmail(
    Session session,
    String registrationToken,
    String password,
  ) async {
    final userId = session.requireUserId;
    await AccountLinkService.finishLinkEmail(
      session,
      userId,
      registrationToken: registrationToken,
      password: password,
    );
    return AccountLinkService.linkedProviders(session, userId);
  }

  /// Deletes the caller's account and everything about them
  /// (decisions.md #119). Their session ends with it.
  Future<void> deleteAccount(Session session) =>
      AccountDeletionService.delete(session, session.requireUserId);
}
