import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/data/repositories/auth_repository_impl.dart';

import '../../../../fakes/fake_client.dart';

void main() {
  test(
    'a sign-out the server never received is a network failure, and the '
    'phone stays signed in',
    () async {
      final client = FakeClient()
        // Serverpod's "no response came back at all".
        ..handler = (_, _, _) =>
            throw const dto.ServerpodClientException('down', -1);
      final repository = AuthRepositoryImpl(client);
      final heard = <AuthUser?>[];
      final sub = repository.authStateChanges().listen(heard.add);
      addTearDown(sub.cancel);

      final result = await repository.signOut();
      await pumpEventQueue();

      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(client.calls.last.method, 'signOutDevice');
      // Nobody was told the user signed out.
      expect(heard, isEmpty);
    },
  );
}
