import 'package:freshcart_server/src/common/business/client_ip.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

void main() {
  String resolve(String remote, [List<String>? forwardedFor]) =>
      ClientIp.resolve(
        remote: IPAddress.parse(remote),
        forwardedFor: forwardedFor,
      );

  final client = IPAddress.parse('203.0.113.7').toString();
  const faked = '198.51.100.1';

  // IPv4 inside IPv6, written in hex because IPAddress.parse doesn't read the
  // dotted form: 127.0.0.1, 203.0.113.7 and 128.0.0.1.
  const mappedLoopback = '::ffff:7f00:1';
  const mappedPublic = '::ffff:cb00:7107';
  const mappedLookalike = '::ffff:8000:1';

  group('behind Caddy (a loopback connection)', () {
    for (final loopback in ['127.0.0.1', mappedLoopback, '::1']) {
      test('$loopback: uses the forwarded address', () {
        expect(resolve(loopback, ['203.0.113.7']), client);
      });
    }

    test('a value the caller put first is ignored', () {
      expect(resolve('127.0.0.1', ['$faked, 203.0.113.7']), client);
    });

    test('so is one sent on its own header line', () {
      expect(resolve(mappedLoopback, [faked, '203.0.113.7']), client);
    });

    test('accepts an IPv6 client', () {
      expect(
        resolve('127.0.0.1', ['2001:db8::1']),
        IPAddress.parse('2001:db8::1').toString(),
      );
    });

    test('falls back to the connection without the header', () {
      expect(
        resolve('127.0.0.1'),
        IPAddress.parse('127.0.0.1').toString(),
      );
    });

    test('falls back to the connection on a malformed value', () {
      expect(
        resolve('127.0.0.1', ['not-an-ip']),
        IPAddress.parse('127.0.0.1').toString(),
      );
    });
  });

  group('a direct connection', () {
    for (final direct in ['203.0.113.7', mappedPublic, '2001:db8::2']) {
      test('$direct: the header is not believed', () {
        expect(
          resolve(direct, [faked]),
          IPAddress.parse(direct).toString(),
        );
      });
    }

    test('addresses that only resemble loopback are not trusted', () {
      for (final lookalike in ['128.0.0.1', '::2', mappedLookalike]) {
        expect(
          resolve(lookalike, [faked]),
          IPAddress.parse(lookalike).toString(),
        );
      }
    });
  });
}
