import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/data/auth_repository_provider.dart';

import '../../../fakes/fake_auth_repository.dart';

/// Publishes after every sign-in, the way `AuthRepositoryImpl._refresh()`
/// does after every port call -- the plain fake doesn't, which is how a
/// provider that invalidated itself on each event looped unnoticed.
class _PublishingAuth extends FakeAuthRepository {
  int signIns = 0;
  final _published = StreamController<AuthUser?>.broadcast();

  @override
  Stream<AuthUser?> authStateChanges() => _published.stream;

  @override
  Future<Result<AuthUser>> signInAnonymously() async {
    signIns++;
    _published.add(user.valueOrNull);
    return user;
  }

  void publish(AuthUser? next) => _published.add(next);
}

void main() {
  late _PublishingAuth auth;
  late ProviderContainer container;

  setUp(() {
    auth = _PublishingAuth();
    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
  });

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  test('signs in once, not again on its own published change', () async {
    final sub = container.listen(currentUserProvider, (_, _) {});
    addTearDown(sub.close);

    await container.read(currentUserProvider.future);
    await settle();

    expect(auth.signIns, 1);
  });

  test('re-reads once when a different user is published', () async {
    final sub = container.listen(currentUserProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(currentUserProvider.future);

    // e.g. onboarding's name step, which writes without invalidating.
    final renamed = AuthUser(
      id: UserId('user-1'),
      displayName: 'Nikos',
      isAnonymous: true,
    );
    auth
      ..user = Ok(renamed)
      ..publish(renamed);
    await settle();

    expect(auth.signIns, 2);
    expect(container.read(currentUserProvider).value?.valueOrNull, renamed);
  });

  test('re-reads on sign-out (a null identity)', () async {
    final sub = container.listen(currentUserProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(currentUserProvider.future);

    auth.publish(null);
    await settle();

    expect(auth.signIns, 2);
  });
}
