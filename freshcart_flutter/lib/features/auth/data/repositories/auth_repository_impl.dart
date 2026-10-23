import 'dart:async';
import 'dart:typed_data';
import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/di/serverpod_client_provider.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';
import 'package:freshcart_flutter/features/auth/data/sources/anonymous_session_bootstrap.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart'
    hide AuthUser;

part 'auth_repository_impl.g.dart';

// The import above is only for `client.auth`. Serverpod's auth package has
// its own `AuthUser` class, which would clash with our domain `AuthUser`.

/// The real [AuthRepository], talking to the Serverpod server.
///
/// The server creates and decides the user's id. The app only reads it.
class AuthRepositoryImpl implements AuthRepository {
  /// Creates the repository against a generated Serverpod [dto.Client].
  AuthRepositoryImpl(this._client);

  final dto.Client _client;
  final StreamController<AuthUser?> _changes =
      StreamController<AuthUser?>.broadcast();

  AuthUser? _currentUser;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> authStateChanges() => _changes.stream;

  @override
  Future<Result<SignIn>> ensureSignedIn() async {
    final session = await _guard(
      () => AnonymousSessionBootstrap.ensureSignedIn(_client),
    );
    return switch (session) {
      Err(:final failure) => Err(failure),
      // Usually: no internet on first launch.
      Ok(value: (authenticated: false, isNewAccount: _)) => const Err(
        Failure.network(),
      ),
      Ok(:final value) => _guard(
        () async => (user: await _refresh(), isNewAccount: value.isNewAccount),
      ),
    };
  }

  @override
  Future<Result<AuthUser>> setDisplayName(String displayName) =>
      _guard(() async {
        await _client.profile.setDisplayName(displayName);
        return _refresh();
      });

  @override
  Future<Result<AuthUser>> setAvatarColor(HexColor color) => _guard(() async {
    await _client.profile.setAvatarColor(color.argb);
    return _refresh();
  });

  @override
  Future<Result<AuthUser>> setAvatarPhoto(Uint8List bytes) => _guard(() async {
    await _client.profile.setAvatarPhoto(ByteData.sublistView(bytes));
    return _refresh();
  });

  @override
  Future<Result<AuthUser>> clearAvatarPhoto() => _guard(() async {
    await _client.profile.clearAvatarPhoto();
    return _refresh();
  });

  @override
  Future<Result<AuthUser>> linkEmail({
    required String email,
    required String password,
  }) => _guard(() async {
    await _client.account.linkEmail(email, password);
    return _refresh();
  });

  @override
  Future<Result<AuthUser>> linkGoogle() async {
    // Not built yet. The server side is ready, but the app still needs a
    // Google OAuth client id and the google_sign_in flow. Returning an
    // honest error is better than a fake that looks like it works.
    // See decisions.md #39.
    return const Err(
      Failure.unexpected('Google sign-in is not configured for this build yet'),
    );
  }

  @override
  Future<Result<void>> signOut() => _guard(() async {
    await _client.auth.signOutDevice();
    _currentUser = null;
    _changes.add(null);
  });

  /// Gets the current user from the server again and tells listeners.
  Future<AuthUser> _refresh() async {
    final me = await _client.profile.me();
    final user = AuthUser(
      id: UserId(me.userId.uuid),
      displayName: me.displayName,
      isAnonymous: me.isAnonymous,
      avatarColor: me.avatarColorArgb == null
          ? null
          : HexColor.fromArgb(me.avatarColorArgb!),
      avatarPhotoUrl: me.avatarPhotoUrl,
    );
    _currentUser = user;
    _changes.add(user);
    return user;
  }

  static Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on Object catch (error) {
      return Err(mapExceptionToFailure(error));
    }
  }
}

/// Supplies the [AuthRepository].
@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepositoryImpl(ref.watch(serverpodClientProvider));
