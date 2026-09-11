import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/data/auth_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_use_case_providers.g.dart';

/// The [SetDisplayName] use case, wired to the auth port.
@riverpod
SetDisplayName setDisplayNameUseCase(Ref ref) =>
    SetDisplayName(ref.watch(authRepositoryProvider));

/// The [SetAvatarPhoto] use case, wired to the auth port.
///
/// `setAvatarColor` and `clearAvatarPhoto` have no such wrapper -- nothing to
/// validate, so they are called on [authRepositoryProvider] directly, the
/// same way `signOut`/`linkGoogle`/`linkEmail` already are.
@riverpod
SetAvatarPhoto setAvatarPhotoUseCase(Ref ref) =>
    SetAvatarPhoto(ref.watch(authRepositoryProvider));
