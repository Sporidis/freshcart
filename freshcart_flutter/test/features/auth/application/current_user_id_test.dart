import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/application/auth/auth_providers.dart';
import 'package:freshcart_flutter/features/auth/data/repositories/auth_repository_impl.dart';

import '../../../fakes/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository auth;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
    addTearDown(auth.dispose);
  });

  test('is the loaded profile\'s id', () async {
    expect(
      await container.read(currentUserIdProvider.future),
      Ok(UserId('user-1')),
    );
  });

  test('without the server, falls back to the session on this phone', () async {
    // A start without a connection: the profile can't load, but the phone
    // still knows whose session it holds.
    auth
      ..user = const Err(Failure.network())
      ..session = UserId('user-1');

    expect(
      await container.read(currentUserIdProvider.future),
      Ok(UserId('user-1')),
    );
  });

  test('with no session at all, the failure stays', () async {
    auth.user = const Err(Failure.network());

    expect(
      (await container.read(currentUserIdProvider.future)).failureOrNull,
      isA<NetworkFailure>(),
    );
  });
}
