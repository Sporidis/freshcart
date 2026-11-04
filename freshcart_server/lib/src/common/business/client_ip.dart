import 'package:serverpod/serverpod.dart';

/// Works out which IP address a request really came from, for per-IP limits.
///
/// In production Caddy sits in front of the server, so every connection comes
/// from loopback and only `X-Forwarded-For` names the real caller.
///
/// That header can be faked, so it is only believed under two conditions:
///
/// - The connection comes from loopback, meaning from Caddy. Anyone reaching
///   the port directly (only the firewall stops them) is judged by their
///   connection.
/// - Only the last entry counts. That is the one Caddy wrote; anything before
///   it could have been sent by the caller.
///
/// Not [RequestExtension.remoteInfo]: it prefers the `Forwarded` header and the
/// first `X-Forwarded-For` entry, which a caller could set to a new value per
/// request and so never reach a limit.
abstract final class ClientIp {
  /// The caller's IP address, or null outside an HTTP request (tests, future
  /// calls).
  static String? of(Session session) {
    final request = session.request;
    if (request == null) return null;
    return resolve(
      remote: request.connectionInfo.remote.address,
      forwardedFor: request.headers['x-forwarded-for'],
    );
  }

  /// The decision behind [of], apart from [Session] so it can be unit tested.
  ///
  /// [remote] is the connection's address, [forwardedFor] the raw values of
  /// the `X-Forwarded-For` header.
  static String resolve({
    required IPAddress remote,
    required Iterable<String>? forwardedFor,
  }) {
    final direct = remote.toString();
    if (!_isLoopback(remote) || forwardedFor == null) return direct;

    final entries = forwardedFor.expand((value) => value.split(','));
    if (entries.isEmpty) return direct;
    try {
      return IPAddress.parse(entries.last.trim()).toString();
    } on FormatException {
      return direct;
    }
  }

  /// Serverpod listens on IPv6 with IPv4 mixed in, so a local IPv4 connection
  /// shows up as `::ffff:127.x.x.x`. That form has to count as loopback too.
  static bool _isLoopback(IPAddress address) {
    final bytes = address.bytes;
    if (bytes.length == 4) return bytes[0] == 127;

    final startsWithZeros = bytes.take(10).every((byte) => byte == 0);
    if (!startsWithZeros) return false;

    final isMappedIpv4 = bytes[10] == 0xff && bytes[11] == 0xff;
    if (isMappedIpv4) return bytes[12] == 127;

    final isIpv6Loopback =
        bytes.skip(10).take(5).every((byte) => byte == 0) && bytes[15] == 1;
    return isIpv6Loopback;
  }
}
