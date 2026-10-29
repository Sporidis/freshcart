import 'package:freshcart_server/src/auth/business/account_link_service.dart';
import 'package:freshcart_server/src/common/business/session_user.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Endpoint to upgrade an anonymous account by adding a login (email).
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
}
