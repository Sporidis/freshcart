import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/auth/application/profile/profile_controller.dart';
import 'package:freshcart_flutter/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

/// The signed-in user's id, as the server sees it.
///
/// Needed to update the screen before the server answers. For example, to
/// show "you checked this" straight away, the app has to know who "you" is.
/// Only the id: for the whole user, use [ProfileController].
///
/// Falls back to the session saved on this phone when the profile couldn't
/// be loaded (a start without a connection): who the user is doesn't need
/// the server, so checking items off and adding them offline still work.
@Riverpod(keepAlive: true)
Future<Result<UserId>> currentUserId(Ref ref) async {
  final profile = await ref.watch(profileControllerProvider.future);
  if (profile case Ok(:final value)) return Ok(value.id);
  final session = ref.read(authRepositoryProvider).sessionUserId;
  return session == null ? profile.map((user) => user.id) : Ok(session);
}

/// The signed-in user's id, or null if not known yet (or sign-in failed).
@riverpod
UserId? signedInUserId(Ref ref) => ref.watch(currentUserIdProvider).dataOrNull;

/// Signs in, once: the only place the app does. `main()` starts it, the
/// splash screen waits for it, and [ProfileController] reads its user.
/// After a sign-out it's invalidated, which signs in again; after a failed
/// start (see [signInFailed]) the app invalidates it once it may work.
@Riverpod(keepAlive: true)
Future<Result<SignIn>> signInResult(Ref ref) =>
    ref.watch(authRepositoryProvider).ensureSignedIn();

/// Finishes when sign-in is done: whether the splash screen should send the
/// user to onboarding (Welcome) instead of their lists.
@riverpod
Future<bool> needsOnboarding(Ref ref) async {
  final signIn = await ref.watch(signInResultProvider.future);
  return signIn.fold(
    ok: (value) => !value.hasProfile,
    // Mostly a returning user who is offline: their lists (cached, or a
    // retry) beat Welcome.
    err: (_) => false,
  );
}

/// Whether [signIn] finished, and failed: the app started without reaching
/// the server. Then nothing tries again by itself, so the app calls this
/// when trying is worth it (back online, back in the app) and invalidates
/// [signInResultProvider] if it's true.
///
/// A sign-in still running doesn't count: in Riverpod 3 a refresh keeps the
/// old result with isLoading true, and starting another would race it.
bool signInFailed(AsyncValue<Result<SignIn>> signIn) => switch (signIn) {
  AsyncData(value: Err(), isLoading: false) => true,
  _ => false,
};

/// Starts a new sign-in if the last one failed, and waits for it.
///
/// For a "Try again" on data that needs a session: when sign-in itself
/// failed (the server was down at start), reloading only the data fails
/// the same way, with "no access", because there is no session to send.
/// Sign-in otherwise only retries on coming back online or back into the
/// app, neither of which happens while the user is looking at the error.
Future<void> retrySignInIfFailed(Ref ref) async {
  if (!signInFailed(ref.read(signInResultProvider))) return;
  ref.invalidate(signInResultProvider);
  await ref.read(signInResultProvider.future);
}
