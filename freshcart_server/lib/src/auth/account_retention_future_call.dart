import 'package:freshcart_server/src/auth/business/account_retention.dart';
import 'package:freshcart_server/src/generated/future_calls.dart';
import 'package:serverpod/serverpod.dart';

/// Runs [AccountRetention] once a day.
///
/// Reschedules itself after every run, also when the run failed, so one
/// bad day doesn't stop the cleanup for good.
class AccountRetentionFutureCall extends FutureCall {
  /// Deletes the anonymous accounts nobody can reach any more, then plans
  /// the next run.
  Future<void> run(Session session) async {
    try {
      final deleted = await AccountRetention.deleteUnreachableAnonymousAccounts(
        session,
      );
      session.log('Account retention: deleted $deleted unreachable accounts');
    } finally {
      await session.serverpod.futureCalls
          .callWithDelay(
            const Duration(days: 1),
            identifier: AccountRetention.jobId,
          )
          .accountRetention
          .run();
    }
  }
}
