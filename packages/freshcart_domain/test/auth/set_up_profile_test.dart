import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

import '../fakes/builders.dart';
import '../fakes/fake_repositories.dart';

void main() {
  group('SetUpProfile', () {
    late FakeAuthPort auth;
    late SetUpProfile setUpProfile;
    final shown = HexColor.fromArgb(0xFF2456A6);

    setUp(() {
      auth = FakeAuthPort();
      setUpProfile = SetUpProfile(auth);
    });

    test('sets the name, then saves the shown colour', () async {
      final result = await setUpProfile('  Alex ', shownColor: shown);

      expect(result.isOk, isTrue);
      expect(auth.setDisplayNameCalls, ['Alex']);
      expect(auth.setAvatarColorCalls, [shown]);
    });

    test('keeps a colour the user already chose', () async {
      auth.setDisplayNameResult = Ok(
        AuthUser(
          id: testUser,
          displayName: 'Alex',
          isAnonymous: true,
          avatarColor: HexColor.fromArgb(0xFFE8791A),
        ),
      );

      await setUpProfile('Alex', shownColor: shown);

      expect(auth.setAvatarColorCalls, isEmpty);
    });

    test('an invalid name saves nothing', () async {
      final result = await setUpProfile('A', shownColor: shown);

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(auth.setDisplayNameCalls, isEmpty);
      expect(auth.setAvatarColorCalls, isEmpty);
    });

    test('a colour that fails to save still leaves the name set', () async {
      auth.setAvatarColorResult = const Err(Failure.network());

      final result = await setUpProfile('Alex', shownColor: shown);

      expect(result.valueOrNull?.displayName, 'Alex');
    });
  });
}
