import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

/// Limits failed joins, so join codes can't be found by guessing.
///
/// Only failures count: re-tapping a valid invite, or several friends
/// joining with one code, never uses the budget.
///
/// Counted per user and per IP address. Per user alone is not enough,
/// because anonymous accounts are free (a new one per guess); per IP alone
/// would let one guesser lock out everyone behind the same router. The
/// user budget is the smaller one, so a single account is stopped before it
/// uses up the network's.
///
/// Uses Serverpod's attempt tracker, which records each attempt outside the
/// caller's transaction and locks per key, so parallel requests can't slip
/// past the limit together.
abstract final class JoinAttempts {
  /// The rolling window failures are counted in.
  static const Duration window = Duration(hours: 1);

  /// Failed joins one user may make per [window].
  static const int maxPerUser = 10;

  /// Failed joins one IP address may make per [window].
  static const int maxPerIp = 30;

  static final _perUser = DatabaseRateLimitedRequestAttemptUtil<String>(
    RateLimitedRequestAttemptConfig(
      domain: 'freshcart',
      source: 'join_failed_user',
      maxAttempts: maxPerUser,
      timeframe: window,
    ),
  );

  static final _perIp = DatabaseRateLimitedRequestAttemptUtil<String>(
    RateLimitedRequestAttemptConfig(
      domain: 'freshcart',
      source: 'join_failed_ip',
      maxAttempts: maxPerIp,
      timeframe: window,
    ),
  );

  /// Throws [TooManyJoinAttemptsException] if [userId] or the caller's IP
  /// address has used up its budget of failed joins.
  static Future<void> requireUnderLimit(
    Session session,
    UuidValue userId,
  ) async {
    final userFailures = await _perUser.countAttempts(
      session,
      nonce: userId.uuid,
    );
    final ip = _ipOf(session);
    final ipFailures = ip == null
        ? 0
        : await _perIp.countAttempts(session, nonce: ip);
    if (userFailures >= maxPerUser || ipFailures >= maxPerIp) {
      throw TooManyJoinAttemptsException();
    }
  }

  /// Records a failed join by [userId] from the caller's IP address.
  static Future<void> recordFailure(Session session, UuidValue userId) async {
    await _perUser.recordAttempt(session, nonce: userId.uuid);
    final ip = _ipOf(session);
    if (ip != null) await _perIp.recordAttempt(session, nonce: ip);
  }

  /// The caller's IP address, or null outside an HTTP request (tests,
  /// future calls). Then only the per-user limit applies.
  static String? _ipOf(Session session) =>
      session.request?.connectionInfo.remote.address.toString();
}
