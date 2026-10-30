import 'package:freshcart_server/src/auth/business/account_deletion_service.dart';
import 'package:freshcart_server/src/auth/business/account_link_service.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

/// How long accounts and their data are kept when nobody uses them
/// (GDPR Art. 5(1)(e), storage limitation).
///
/// One number decides both: [sessionLifetime] is how long a session may go
/// unused before it stops working. For an anonymous account, the session is
/// the only key, so once it has expired nobody can ever reach the account
/// again. That is exactly when it is deleted: keeping it any longer keeps
/// personal data for no one. Accounts with an email or Google login can
/// always sign in again, so they are never deleted for being quiet.
abstract final class AccountRetention {
  /// How long a session may go unused before it stops working: a year, so
  /// once-a-year use (a holiday, the barbecue season) still finds the list.
  /// Serverpod's default is 14 days, after which an anonymous user would
  /// lose their account.
  static const Duration sessionLifetime = Duration(days: 365);

  /// The id of the scheduled daily cleanup, so a restart replaces it
  /// instead of adding a second one.
  static const String jobId = 'account-retention';

  /// Deletes every anonymous account that can no longer sign in, the same
  /// way as a user deleting it themselves ([AccountDeletionService]), and
  /// then the expired session tokens. Returns how many accounts went.
  static Future<int> deleteUnreachableAnonymousAccounts(
    Session session, {
    DateTime? now,
  }) async {
    final cutoff = (now ?? DateTime.now().toUtc()).subtract(sessionLifetime);
    final unreachable = await _unreachableAnonymous(session, cutoff);
    for (final userId in unreachable) {
      await AccountDeletionService.delete(session, userId);
    }
    await AuthServices.getTokenManager<JwtTokenManager>().jwt.admin
        .deleteExpiredRefreshTokens(session);
    return unreachable.length;
  }

  /// The anonymous accounts with no session used since [cutoff]: nobody
  /// can sign into them any more.
  static Future<List<UuidValue>> _unreachableAnonymous(
    Session session,
    DateTime cutoff,
  ) async {
    // Younger than a year can't have been quiet for a year.
    final candidates = await AuthUser.db.find(
      session,
      where: (t) => t.createdAt < cutoff,
    );
    final unreachable = <UuidValue>[];
    for (final candidate in candidates) {
      final id = candidate.id!;
      final recentSessions = await RefreshToken.db.count(
        session,
        where: (t) => t.authUserId.equals(id) & (t.lastUpdatedAt >= cutoff),
      );
      if (recentSessions > 0) continue;
      // An email or Google login can always sign in again.
      final providers = await AccountLinkService.linkedProviders(session, id);
      if (providers.contains(LinkedProvider.anonymous)) unreachable.add(id);
    }
    return unreachable;
  }
}
