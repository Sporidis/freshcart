import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

import '../fakes/fake_repositories.dart';

void main() {
  group('SetDisplayName', () {
    late FakeAuthRepository auth;
    late SetDisplayName setDisplayName;

    setUp(() {
      auth = FakeAuthRepository();
      setDisplayName = SetDisplayName(auth);
    });

    test('stores a valid name', () async {
      final result = await setDisplayName('Alex Janssens');

      expect(result.isOk, isTrue);
      expect(auth.setDisplayNameCalls.single, 'Alex Janssens');
    });

    test('trims surrounding whitespace', () async {
      await setDisplayName('  Alex  ');

      expect(auth.setDisplayNameCalls.single, 'Alex');
    });

    test('rejects a name shorter than the minimum', () async {
      final result = await setDisplayName('A');

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(auth.setDisplayNameCalls, isEmpty);
    });

    // The old check measured the raw string, so whitespace counted towards
    // the minimum length and "  " was accepted as a name.
    test('rejects whitespace that is only long enough untrimmed', () async {
      final result = await setDisplayName('   ');

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(auth.setDisplayNameCalls, isEmpty);
    });

    test('rejects a name longer than the maximum', () async {
      final result = await setDisplayName(
        'x' * (AuthUser.maxDisplayNameLength + 1),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(auth.setDisplayNameCalls, isEmpty);
    });

    test('surfaces a port failure unchanged', () async {
      auth.setDisplayNameResult = const Err<AuthUser>(Failure.unauthorized());

      final result = await setDisplayName('Alex');

      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });
  });
}
