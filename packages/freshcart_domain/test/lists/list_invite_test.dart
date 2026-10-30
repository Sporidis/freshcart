import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

import '../fakes/builders.dart';

void main() {
  final code = JoinCode.parse('ABC23').valueOrNull!;

  group('ListInvite', () {
    test('a new invite is valid for the lifetime from now', () {
      final invite = ListInvite.openAt(code, testNow);

      expect(invite.expiresAt, testNow.add(ListInvite.lifetime));
    });

    test('is open until it expires, not at or after', () {
      final invite = ListInvite.openAt(code, testNow);
      final expiry = invite.expiresAt;

      expect(invite.isOpenAt(testNow), isTrue);
      expect(
        invite.isOpenAt(expiry.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(invite.isOpenAt(expiry), isFalse);
      expect(invite.isOpenAt(expiry.add(const Duration(days: 1))), isFalse);
    });

    test('keeps a sensible window to reuse an invite', () {
      // Reusing must be possible at all, and a reused invite must still
      // leave the friend some time to open it.
      expect(ListInvite.minRemainingToReuse, greaterThan(Duration.zero));
      expect(ListInvite.minRemainingToReuse, lessThan(ListInvite.lifetime));
    });

    test('a fresh invite is reused', () {
      final invite = ListInvite.openAt(code, testNow);

      expect(invite.isWorthReusingAt(testNow), isTrue);
    });

    test('reused while exactly the minimum is left, not once less is', () {
      final invite = ListInvite.openAt(code, testNow);
      final lastReuse = invite.expiresAt.subtract(
        ListInvite.minRemainingToReuse,
      );

      expect(invite.isWorthReusingAt(lastReuse), isTrue);
      expect(
        invite.isWorthReusingAt(lastReuse.add(const Duration(seconds: 1))),
        isFalse,
      );
    });

    test('an expired invite is never reused', () {
      final invite = ListInvite.openAt(code, testNow);

      expect(invite.isWorthReusingAt(invite.expiresAt), isFalse);
    });
  });
}
