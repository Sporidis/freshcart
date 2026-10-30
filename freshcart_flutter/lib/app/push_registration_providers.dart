import 'dart:async';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/application/auth/auth_providers.dart';
import 'package:freshcart_flutter/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'push_registration_providers.g.dart';

/// Registers this phone for push every time someone signs in: at app start,
/// and again after a sign-out signs in a fresh account.
///
/// The server moves a token that is already registered to the caller, so
/// this is also what takes the phone away from the previous account if
/// unregistering it on sign-out failed.
///
/// Returns nothing. It only has to exist, so `app.dart` watches it once to
/// start it. We don't wait for registering: if it fails, the app still
/// works, the user just won't get push notifications.
@Riverpod(keepAlive: true)
void registerPushOnSignIn(Ref ref) {
  ref.listen(signInResultProvider, (_, next) {
    // Only a finished, successful sign-in. In Riverpod 3 a refresh in
    // progress is still AsyncData, carrying the previous user with
    // isLoading true: that one must not be registered again.
    if (next case AsyncData(value: Ok(), isLoading: false)) {
      unawaited(ref.read(notificationRepositoryProvider).registerDevice());
    }
  }, fireImmediately: true);
}
