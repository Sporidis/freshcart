import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/offline/repositories/local_data_repository_impl.dart';
import 'package:freshcart_flutter/features/auth/application/auth/auth_providers.dart';
import 'package:freshcart_flutter/features/auth/application/profile/profile_controller.dart';
import 'package:freshcart_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:freshcart_flutter/features/notifications/data/repositories/notification_repository_impl.dart';

import '../../../fakes/fake_auth_repository.dart';
import '../../../fakes/fake_local_data_repository.dart';
import '../../../fakes/fake_notification_repository.dart';

/// Publishes on every sign-in, the way `AuthRepositoryImpl._refresh()` does
/// after every port call -- the plain fake doesn't, which is how a build()
/// that invalidated itself on each event looped unnoticed.
class _PublishingAuth extends FakeAuthRepository {
  int signIns = 0;
  final _published = StreamController<AuthUser?>.broadcast();

  @override
  Stream<AuthUser?> authStateChanges() => _published.stream;

  @override
  Future<Result<SignIn>> ensureSignedIn() async {
    signIns++;
    _published.add(user.valueOrNull);
    return user.map((u) => (user: u, hasProfile: true));
  }

  @override
  Future<Result<void>> signOut() async {
    signOutCalls++;
    // Like AuthRepositoryImpl: listeners hear the sign-out at once.
    _published.add(null);
    return const Ok(null);
  }
}

/// Clears like the real drift store: after real I/O, not instantly. That
/// gap is what let a sign-out start two sign-ins.
class _SlowLocalData extends FakeLocalDataRepository {
  @override
  Future<void> clear() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await super.clear();
  }
}

void main() {
  late _PublishingAuth auth;
  late ProviderContainer container;

  setUp(() {
    auth = _PublishingAuth();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        notificationRepositoryProvider.overrideWithValue(
          FakeNotificationRepository(),
        ),
        localDataRepositoryProvider.overrideWithValue(_SlowLocalData()),
      ],
    );
    addTearDown(container.dispose);
  });

  test('a sign-out signs in exactly one new account', () async {
    final sub = container.listen(profileControllerProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(profileControllerProvider.future);

    await container.read(profileControllerProvider.notifier).signOut();
    await container.read(profileControllerProvider.future);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // The first sign-in, and one for the fresh account: never two (each
    // would be a new anonymous account on the server).
    expect(auth.signIns, 2);
  });

  test('signs in once, not again on its own published change', () async {
    final sub = container.listen(profileControllerProvider, (_, _) {});
    addTearDown(sub.close);

    await container.read(profileControllerProvider.future);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(auth.signIns, 1);
  });

  test(
    'the app\'s sign-in and the profile sign in once between them',
    () async {
      await container.read(signInResultProvider.future);
      await container.read(profileControllerProvider.future);

      expect(auth.signIns, 1);
    },
  );

  test(
    'a successful write updates the profile without re-signing in',
    () async {
      await container.read(profileControllerProvider.future);

      // The fake's link succeeds and clears anonymity by default.
      final profile = container.read(profileControllerProvider.notifier);
      await profile.startLinkEmail(email: 'a@b.c', password: 'secret12');
      final failure = await profile.linkEmail(
        requestId: 'request-1',
        code: '12345678',
        password: 'secret12',
      );

      expect(failure, isNull);
      expect(
        container
            .read(profileControllerProvider)
            .value
            ?.valueOrNull
            ?.isAnonymous,
        isFalse,
      );
      expect(auth.signIns, 1);
    },
  );
}
