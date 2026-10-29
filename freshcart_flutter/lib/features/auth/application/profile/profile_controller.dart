import 'dart:typed_data';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/application/auth/auth_providers.dart';
import 'package:freshcart_flutter/features/auth/data/repositories/auth_repository_impl.dart';
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
    // When a new user arrives, just put it in the state. Only a sign-out
    // (null) needs a fresh sign-in, which rebuilds this.
    final subscription = auth.authStateChanges().listen((user) {
      if (user == null) {
        ref.invalidate(signInResultProvider);
      } else {
        state = AsyncData(Ok(user));
      }
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

  /// Adds an email and password to the anonymous account. Then the user
  /// doesn't lose their lists if they lose their phone.
  Future<Failure?> linkEmail({
    required String email,
    required String password,
  }) => _write(
    () => LinkEmail(_auth)(email: email, password: password),
  );

  /// Signs out. If it works, the profile is loaded again from scratch.
  Future<Failure?> signOut() async {
    switch (await _auth.signOut()) {
      case Ok():
        // A fresh anonymous account, the same as a first launch.
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
