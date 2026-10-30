import 'dart:typed_data';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/offline/repositories/local_data_repository_impl.dart';
import 'package:freshcart_flutter/features/auth/application/auth/auth_providers.dart';
import 'package:freshcart_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:freshcart_flutter/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_controller.g.dart';

/// The signed-in user's profile, and all the changes that can be made to it.
///
/// Screens don't call [AuthRepository] directly, they call this. Each method
/// returns a [Failure], or null if it worked. The screen only decides how
/// to show the result.
@Riverpod(keepAlive: true)
class ProfileController extends _$ProfileController {
  AuthRepository get _auth => ref.read(authRepositoryProvider);

  /// The signed-in user (from [signInResultProvider]; this never signs in
  /// itself), kept up to date with every change.
  @override
  Future<Result<AuthUser>> build() async {
    final auth = ref.watch(authRepositoryProvider);
    // When a new user arrives, just put it in the state. A sign-out (null)
    // is left to [signOut], which signs in again only once this phone's
    // data is cleared. Signing in here too would start a second sign-in
    // (a second anonymous account) while the first one is running.
    final subscription = auth.authStateChanges().listen((user) {
      if (user != null) state = AsyncData(Ok(user));
    });
    ref.onDispose(subscription.cancel);
    return (await ref.watch(signInResultProvider.future)).map(
      (signIn) => signIn.user,
    );
  }

  /// Changes the user's name.
  Future<Failure?> setDisplayName(String name) =>
      _write(() => SetDisplayName(ref.read(authRepositoryProvider))(name));

  /// Changes the user's avatar colour.
  Future<Failure?> setAvatarColor(HexColor color) =>
      _write(() => _auth.setAvatarColor(color));

  /// Uploads [bytes] as the user's avatar photo.
  Future<Failure?> setAvatarPhoto(Uint8List bytes) =>
      _write(() => SetAvatarPhoto(ref.read(authRepositoryProvider))(bytes));

  Future<Failure?> clearAvatarPhoto() => _write(_auth.clearAvatarPhoto);

  /// The first step of adding an email: checks [password] and emails a
  /// code to [email]. Returns the request id that [linkEmail] needs.
  ///
  /// Doesn't change the profile, so it skips [_write].
  Future<Result<String>> startLinkEmail({
    required String email,
    required String password,
  }) => StartLinkEmail(_auth)(email: email, password: password);

  /// Adds the email of [requestId] and [password] to the anonymous account,
  /// if [code] is the one that was emailed. Then the user doesn't lose
  /// their lists if they lose their phone.
  Future<Failure?> linkEmail({
    required String requestId,
    required String code,
    required String password,
  }) => _write(
    () => LinkEmail(_auth)(
      requestId: requestId,
      code: code,
      password: password,
    ),
  );

  /// How many changes made offline would be lost by signing out now, for
  /// the "are you sure?" question.
  Future<int> pendingChangeCount() =>
      ref.read(localDataRepositoryProvider).pendingChangeCount();

  /// Signs out, leaving nothing of the account on this phone ([SignOut]).
  /// If it works, the profile is loaded again from scratch.
  Future<Failure?> signOut() async {
    final signOut = SignOut(
      _auth,
      ref.read(notificationRepositoryProvider),
      ref.read(localDataRepositoryProvider),
    );
    switch (await signOut()) {
      case Ok():
        // A fresh anonymous account, the same as a first launch. The only
        // place a sign-out signs in again, and only now that the old
        // account's data is gone from this phone.
        ref.invalidate(signInResultProvider);
        return null;
      case Err(:final failure):
        return failure;
    }
  }

  /// Runs one profile change and updates [state] with the result.
  Future<Failure?> _write(
    Future<Result<AuthUser>> Function() action,
  ) async {
    final result = await action();
    return switch (result) {
      Ok(:final value) => () {
        state = AsyncData(Ok(value));
        return null;
      }(),
      Err(:final failure) => failure,
    };
  }
}
