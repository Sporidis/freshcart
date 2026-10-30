import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

import '../fakes/fake_repositories.dart';

void main() {
  late List<String> calls;
  late FakeAuthRepository auth;
  late FakeNotificationRepository notifications;
  late FakeLocalDataRepository localData;
  late SignOut signOut;

  setUp(() {
    calls = [];
    auth = FakeAuthRepository()..calls = calls;
    notifications = FakeNotificationRepository(calls);
    localData = FakeLocalDataRepository(calls);
    signOut = SignOut(auth, notifications, localData);
  });

  group('SignOut', () {
    test(
      'stops push, signs out, then clears the device, in that order',
      () async {
        final result = await signOut();

        expect(result.isOk, isTrue);
        expect(calls, ['unregisterDevice', 'signOut', 'clear']);
      },
    );

    test('still signs out when stopping push fails', () async {
      notifications.unregisterResult = const Err(Failure.network());

      final result = await signOut();

      expect(result.isOk, isTrue);
      expect(calls, ['unregisterDevice', 'signOut', 'clear']);
    });

    test('keeps the device data when signing out fails', () async {
      auth.signOutResult = const Err(Failure.network());

      final result = await signOut();

      expect(result.failureOrNull, const Failure.network());
      expect(calls, isNot(contains('clear')));
    });
  });
}
