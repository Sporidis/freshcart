import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/di/serverpod_client_provider.dart';
import 'package:freshcart_flutter/features/auth/data/auth_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository_provider.g.dart';

/// Supplies the [AuthPort].
@Riverpod(keepAlive: true)
AuthPort authRepository(Ref ref) =>
    AuthRepositoryImpl(ref.watch(serverpodClientProvider));

/// The signed-in user, re-read whenever the identity changes.
///
/// Drives the upgrade nudge: an anonymous session lives only in local storage,
/// so losing the device loses every shared list.
@Riverpod(keepAlive: true)
Future<Result<AuthUser>> currentUser(Ref ref) async {
  final auth = ref.watch(authRepositoryProvider);
  final result = await auth.signInAnonymously();
  final current = result.valueOrNull;
  // Re-read only when the published identity actually differs from the one
  // this build returned. The port publishes after *every* call -- including
  // the signInAnonymously() above -- so invalidating on each event re-ran
  // this build, which published again, which invalidated again: an endless
  // sign-in loop. Subscribing only after sign-in also means this build's
  // own publish is never seen (a broadcast stream doesn't replay).
  final subscription = auth.authStateChanges().listen((user) {
    if (user != current) ref.invalidateSelf();
  });
  ref.onDispose(subscription.cancel);
  return result;
}
