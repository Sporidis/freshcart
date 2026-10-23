import 'dart:async';
import 'dart:typed_data';

import 'package:freshcart_domain/freshcart_domain.dart';

/// An in-memory [AuthRepository] for presentation tests.
class FakeAuthRepository implements AuthRepository {
  /// The identity [ensureSignedIn] and the link calls resolve to.
  Result<AuthUser> user = Ok(
    AuthUser(id: UserId('user-1'), displayName: 'Nikolaos', isAnonymous: true),
  );

  /// What [linkEmail] returns. Defaults to succeeding and clearing anonymity.
  Result<AuthUser>? linkResult;

  /// Credentials passed to [linkEmail], in order.
  final List<({String email, String password})> linkCalls = [];

  /// How many times [signOut] was called.
  int signOutCalls = 0;

  final StreamController<AuthUser?> _changes =
      StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? get currentUser => user.valueOrNull;

  @override
  Stream<AuthUser?> authStateChanges() => _changes.stream;

  /// Makes [next] the current identity and publishes it, the way the real
  /// port does after a change made elsewhere (another device, the server).
  void publish(AuthUser next) {
    user = Ok(next);
    _changes.add(next);
  }

  /// Whether [ensureSignedIn] reports a brand-new account.
  bool isNewAccount = false;

  @override
  Future<Result<SignIn>> ensureSignedIn() async =>
      user.map((u) => (user: u, isNewAccount: isNewAccount));

  /// Names passed to [setDisplayName], in order.
  final List<String> setDisplayNameCalls = [];

  @override
  Future<Result<AuthUser>> setDisplayName(String displayName) async {
    setDisplayNameCalls.add(displayName);
    final current = user.valueOrNull;
    if (current != null) {
      user = Ok(current.copyWith(displayName: displayName));
    }
    return user;
  }

  /// Colours passed to [setAvatarColor], in order.
  final List<HexColor> setAvatarColorCalls = [];

  @override
  Future<Result<AuthUser>> setAvatarColor(HexColor color) async {
    setAvatarColorCalls.add(color);
    final current = user.valueOrNull;
    if (current != null) user = Ok(current.copyWith(avatarColor: color));
    return user;
  }

  /// Uploads passed to [setAvatarPhoto], in order.
  final List<Uint8List> setAvatarPhotoCalls = [];

  @override
  Future<Result<AuthUser>> setAvatarPhoto(Uint8List bytes) async {
    setAvatarPhotoCalls.add(bytes);
    final current = user.valueOrNull;
    if (current != null) {
      user = Ok(
        current.copyWith(
          avatarPhotoUrl:
              'https://example.test/avatars/${current.id.value}.jpg',
        ),
      );
    }
    return user;
  }

  /// How many times [clearAvatarPhoto] was called.
  int clearAvatarPhotoCalls = 0;

  @override
  Future<Result<AuthUser>> clearAvatarPhoto() async {
    clearAvatarPhotoCalls++;
    final current = user.valueOrNull;
    if (current != null) user = Ok(current.copyWith(avatarPhotoUrl: null));
    return user;
  }

  @override
  Future<Result<AuthUser>> linkEmail({
    required String email,
    required String password,
  }) async {
    linkCalls.add((email: email, password: password));
    final result =
        linkResult ??
        Ok(
          AuthUser(
            id: UserId('user-1'),
            displayName: 'Nikolaos',
            isAnonymous: false,
            email: email,
          ),
        );
    if (result.isOk) user = result;
    return result;
  }

  @override
  Future<Result<AuthUser>> linkGoogle() async => const Err(
    Failure.unexpected('Google sign-in is not configured'),
  );

  /// What [signOut] returns.
  Result<void> signOutResult = const Ok<void>(null);

  @override
  Future<Result<void>> signOut() async {
    signOutCalls++;
    return signOutResult;
  }

  /// Closes the change stream. Call from a test teardown.
  Future<void> dispose() => _changes.close();
}

/// A successful [AuthRepository.ensureSignedIn], for overriding
/// `signInResultProvider` in tests that don't need a whole fake auth.
SignIn aSignIn({bool isNewAccount = false}) => (
  user: AuthUser(
    id: UserId('user-1'),
    displayName: 'Nikolaos',
    isAnonymous: true,
  ),
  isNewAccount: isNewAccount,
);
