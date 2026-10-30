import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app/push_registration_providers.dart';
import 'package:freshcart_flutter/features/auth/application/auth/auth_providers.dart';
import 'package:freshcart_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:freshcart_flutter/features/notifications/data/repositories/notification_repository_impl.dart';

import '../fakes/fake_auth_repository.dart';
import '../fakes/fake_notification_repository.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeNotificationRepository notifications;
  late ProviderContainer container;

  setUp(() {
    auth = FakeAuthRepository();
    notifications = FakeNotificationRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        notificationRepositoryProvider.overrideWithValue(notifications),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(auth.dispose);
  });

  /// Starts the coordinator, as `app.dart` does.
  void start() {
    final sub = container.listen(registerPushOnSignInProvider, (_, _) {});
    addTearDown(sub.close);
  }

  test('registers the phone once sign-in has finished', () async {
    start();
    await container.read(signInResultProvider.future);
    await pumpEventQueue();

    expect(notifications.registerDeviceCallCount, 1);
  });

  test('registers again for the account a sign-out signs in', () async {
    start();
    await container.read(signInResultProvider.future);
    await pumpEventQueue();

    // What a sign-out does: a fresh sign-in.
    container.invalidate(signInResultProvider);
    await container.read(signInResultProvider.future);
    await pumpEventQueue();

    expect(notifications.registerDeviceCallCount, 2);
  });

  test('a failed sign-in registers nothing', () async {
    auth.user = const Err(Failure.network());
    start();
    await container.read(signInResultProvider.future);
    await pumpEventQueue();

    expect(notifications.registerDeviceCallCount, 0);
  });
}
