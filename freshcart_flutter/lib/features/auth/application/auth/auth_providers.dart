import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/auth/application/profile/profile_controller.dart';
import 'package:freshcart_flutter/features/auth/data/sources/anonymous_session_bootstrap.dart';
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

/// Finishes when sign-in is done. `true` means a brand-new user (show
/// onboarding), `false` means a returning user.
///
/// The splash screen uses this, so it doesn't need to know about the data
/// layer.
@riverpod
Future<bool> isNewIdentity(Ref ref) async =>
    (await ref.watch(authBootstrapProvider.future)).isNewIdentity;
