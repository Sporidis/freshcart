import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:test/test.dart';

import '../fakes/fake_repositories.dart';

void main() {
  late List<String> calls;
  late FakeAuthRepository auth;
  late DeleteAccount deleteAccount;

  setUp(() {
    calls = [];
    auth = FakeAuthRepository()..calls = calls;
    deleteAccount = DeleteAccount(auth, FakeLocalDataRepository(calls));
  });

  group('DeleteAccount', () {
    test('deletes on the server, then clears the phone', () async {
      final result = await deleteAccount();

      expect(result.isOk, isTrue);
      expect(calls, ['deleteAccount', 'clear']);
    });

    test('keeps the phone\'s data when the server did not delete', () async {
      auth.deleteAccountResult = const Err(Failure.network());

      final result = await deleteAccount();

      expect(result.failureOrNull, const Failure.network());
      expect(calls, isNot(contains('clear')));
    });
  });
}
