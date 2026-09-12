import 'dart:async';
import 'dart:typed_data';

import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_mapper.dart';
import 'package:freshcart_flutter/features/auth/data/anonymous_session_bootstrap.dart';
// Imported for the `client.auth` extension only. The auth module ships its
// own AuthUser, which would otherwise collide with the domain entity of the
// same name — a good illustration of why the domain owns its own types.
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart'
    hide AuthUser;

/// The Serverpod-backed [AuthPort].
///
/// Identity is minted server-side and read back, never asserted by the client.
class AuthRepositoryImpl implements AuthPort {
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
  Future<Result<AuthUser>> signInAnonymously() => _guard(() async {
    await AnonymousSessionBootstrap.ensureSignedIn(_client);
    return _refresh();
  });

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
    // Deliberately not faked. Google linking needs an OAuth client id and the
    // google_sign_in flow to obtain an id token; the *server* half already
    // exists via GoogleIdpAdmin, which accepts an existing authUserId exactly
    // as the email path does. Returning a clear failure beats a stub that looks
    // wired up. See docs/decisions.md #39.
    return const Err(
      Failure.validation(
        'google',
        'Google sign-in is not configured for this build yet',
      ),
    );
  }

  @override
  Future<Result<void>> signOut() => _guard(() async {
    await _client.auth.signOutDevice();
    _currentUser = null;
    _changes.add(null);
  });

  /// Re-reads the identity from the server and publishes it.
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
