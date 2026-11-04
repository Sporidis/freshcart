import 'package:freshcart_server/src/common/business/client_ip.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

/// Limits new anonymous accounts per IP address, because anyone can create one
/// without logging in.
///
/// Replaces the limit built into `AnonymousIdpConfig`, which reads the
/// connection's address. Behind Caddy that is always loopback, so all users
/// would share one budget and one person could block sign-up for everyone.
/// The numbers are the package's own defaults.
abstract final class AnonymousSignupLimit {
  /// The rolling window attempts are counted in.
  static const Duration window = Duration(hours: 1);

  /// New accounts one IP address may create per [window].
  static const int maxPerIp = 100;

  static final _perIp = DatabaseRateLimitedRequestAttemptUtil<String>(
    RateLimitedRequestAttemptConfig(
      domain: 'freshcart',
      source: 'anonymous_signup',
      maxAttempts: maxPerIp,
      timeframe: window,
    ),
  );

  /// Runs before an anonymous account is created. Without an HTTP request
  /// there's no IP address to count against, so nothing is limited.
  static Future<void> check(
    Session session, {
    String? token,
    required Transaction? transaction,
  }) async {
    final ip = ClientIp.of(session);
    if (ip != null) await requireUnderLimit(session, ip);
  }

  /// Counts an attempt from [ip], and throws
  /// [AnonymousAccountBlockedException] once it is over [maxPerIp].
  static Future<void> requireUnderLimit(Session session, String ip) async {
    if (await _perIp.hasTooManyAttempts(session, nonce: ip)) {
      throw AnonymousAccountBlockedException(
        reason: AnonymousAccountBlockedExceptionReason.tooManyAttempts,
      );
    }
  }
}
