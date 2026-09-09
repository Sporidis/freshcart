import 'package:freshcart_server/src/auth/business/account_link_service.dart';
import 'package:freshcart_server/src/common/business/session_user.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Upgrading an anonymous account by attaching credentials to it.
class AccountEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Which providers are attached to the caller's account.
  Future<List<LinkedProvider>> linkedProviders(Session session) =>
      AccountLinkService.linkedProviders(session, session.requireUserId);

  /// Attaches an email/password credential to the caller's existing account.
  ///
  /// The caller keeps the same `authUserId`, so nothing they created moves.
  Future<List<LinkedProvider>> linkEmail(
    Session session,
    String email,
    String password,
  ) async {
    final userId = session.requireUserId;
    await AccountLinkService.linkEmail(
      session,
      userId,
      email: email,
      password: password,
    );
    return AccountLinkService.linkedProviders(session, userId);
  }
}
