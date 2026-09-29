import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/auth/data/sources/anonymous_session_bootstrap.dart';
import 'package:freshcart_flutter/features/auth/data/sources/current_user_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

/// Who the signed-in user is, or null until that's known (or if it failed).
///
/// The application layer's one doorway to [currentUserIdProvider], which
/// stays in `data/` because repositories need it too. Screens ask this --
/// or better, a question built on it like `isListOwner` -- instead of
/// reaching into the data layer themselves.
@riverpod
UserId? signedInUserId(Ref ref) => ref.watch(currentUserIdProvider).dataOrNull;

/// Resolves once sign-in has finished: true for a brand-new identity (send
/// them through onboarding), false for a restored one.
///
/// Splash only needs this one answer, not the bootstrap's whole result --
/// and not to know that the bootstrap lives in the data layer.
@riverpod
Future<bool> isNewIdentity(Ref ref) async =>
    (await ref.watch(authBootstrapProvider.future)).isNewIdentity;
