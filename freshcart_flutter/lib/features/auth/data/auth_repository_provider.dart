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
  final subscription = auth.authStateChanges().listen(
    (_) => ref.invalidateSelf(),
  );
  ref.onDispose(subscription.cancel);
  return auth.signInAnonymously();
}
