import 'dart:typed_data';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_controller.g.dart';

/// The signed-in user's profile, and every change a screen can make to it.
///
/// Screens never call the [AuthPort] themselves: each action here returns a
/// [Failure] (or null on success) and keeps this provider's state in step,
/// so the widget only decides how to *show* the outcome -- a message, a
/// navigation -- the same split `ItemsScreenController` makes.
@Riverpod(keepAlive: true)
class ProfileController extends _$ProfileController {
  AuthPort get _auth => ref.read(authRepositoryProvider);

  /// Signs in (restoring or creating an anonymous session) and follows the
  /// identity as it changes underneath us.
  @override
  Future<Result<AuthUser>> build() async {
    final auth = ref.watch(authRepositoryProvider);
    // Adopts the published user rather than invalidating: the port publishes
    // after *every* call, including the `signInAnonymously()` just below, so
    // re-running build() on each event re-published, re-ran build(), and
    // looped -- thousands of sign-ins a second. Only a sign-out (null) needs
    // a genuine re-read.
    final subscription = auth.authStateChanges().listen((user) {
      if (user == null) {
        ref.invalidateSelf();
      } else {
        state = AsyncData(Ok(user));
      }
    });
    ref.onDispose(subscription.cancel);
    return auth.signInAnonymously();
  }

  Future<Failure?> setDisplayName(String name) =>
      _write(() => SetDisplayName(ref.read(authRepositoryProvider))(name));

  Future<Failure?> setAvatarColor(HexColor color) =>
      _write(() => _auth.setAvatarColor(color));

  Future<Failure?> setAvatarPhoto(Uint8List bytes) =>
      _write(() => SetAvatarPhoto(ref.read(authRepositoryProvider))(bytes));

  Future<Failure?> clearAvatarPhoto() => _write(_auth.clearAvatarPhoto);

  /// Upgrades the anonymous account to email + password, so losing the
  /// device no longer loses every shared list.
  Future<Failure?> linkEmail({
    required String email,
    required String password,
  }) => _write(() => _auth.linkEmail(email: email, password: password));

  /// Signs out. Returns no user, so on success the profile is simply
  /// re-read from scratch.
  Future<Failure?> signOut() async {
    switch (await _auth.signOut()) {
      case Ok():
        ref.invalidateSelf();
        return null;
      case Err(:final failure):
        return failure;
    }
  }

  /// Runs one profile write and keeps [state] in step with it.
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
