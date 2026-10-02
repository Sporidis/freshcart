import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/auth/data/sources/anonymous_session_bootstrap.dart';
import 'package:freshcart_flutter/features/auth/data/sources/current_user_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

/// The signed-in user's id, or null if not known yet (or sign-in failed).
///
/// Screens use this instead of [currentUserIdProvider] directly, because
/// that one lives in the data layer (repositories need it too).
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
