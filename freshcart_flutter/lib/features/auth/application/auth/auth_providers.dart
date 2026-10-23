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
@Riverpod(keepAlive: true)
Future<Result<UserId>> currentUserId(Ref ref) async =>
    (await ref.watch(profileControllerProvider.future)).map((user) => user.id);

/// The signed-in user's id, or null if not known yet (or sign-in failed).
@riverpod
UserId? signedInUserId(Ref ref) => ref.watch(currentUserIdProvider).dataOrNull;

/// Signs in, once: the only place the app does. `main()` starts it, the
/// splash screen waits for it, and [ProfileController] reads its user.
/// After a sign-out it's invalidated, which signs in again.
@Riverpod(keepAlive: true)
Future<Result<SignIn>> signInResult(Ref ref) =>
    ref.watch(authRepositoryProvider).ensureSignedIn();

/// Finishes when sign-in is done. `true` means a brand-new user (show
/// onboarding), `false` a returning one, or a sign-in that failed (the
/// lists screen then shows what's wrong).
@riverpod
Future<bool> isNewAccount(Ref ref) async =>
    (await ref.watch(signInResultProvider.future)).valueOrNull?.isNewAccount ??
    false;
