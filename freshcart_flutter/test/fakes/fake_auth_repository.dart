import 'dart:async';
import 'dart:typed_data';

import 'package:freshcart_domain/freshcart_domain.dart';

/// An in-memory [AuthRepository] for presentation tests.
class FakeAuthRepository implements AuthRepository {
  /// The identity [ensureSignedIn] and the link calls resolve to.
  Result<AuthUser> user = Ok(
    AuthUser(id: UserId('user-1'), displayName: 'Nikolaos', isAnonymous: true),
  );

  /// What [finishLinkEmail] returns. Defaults to succeeding and clearing
  /// anonymity, with the email from the last [startLinkEmail].
  Result<AuthUser>? finishLinkResult;

  /// Emails passed to [startLinkEmail], in order.
  final List<String> startLinkCalls = [];

  /// Arguments passed to [finishLinkEmail], in order.
  final List<({String requestId, String code, String password})>
  finishLinkCalls = [];

  /// How many times [signOut] was called.
  int signOutCalls = 0;

  final StreamController<AuthUser?> _changes =
      StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? get currentUser => user.valueOrNull;

  /// What [sessionUserId] returns: the id of the session saved on the
  /// phone, which a test can set while [currentUser] is still unknown.
  UserId? session;

  @override
  UserId? get sessionUserId => session;

  @override
  Stream<AuthUser?> authStateChanges() => _changes.stream;

  /// Makes [next] the current identity and publishes it, the way the real
  /// port does after a change made elsewhere (another device, the server).
  void publish(AuthUser next) {
    user = Ok(next);
    _changes.add(next);
  }

  /// Whether [ensureSignedIn] reports a profile (false: onboarding next).
  bool hasProfile = true;

  @override
  Future<Result<SignIn>> ensureSignedIn() async =>
      user.map((u) => (user: u, hasProfile: hasProfile));

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
  Future<Result<String>> startLinkEmail(String email) async {
    startLinkCalls.add(email);
    return const Ok('request-1');
  }

  @override
  Future<Result<AuthUser>> finishLinkEmail({
    required String requestId,
    required String code,
    required String password,
  }) async {
    finishLinkCalls.add((requestId: requestId, code: code, password: password));
    final result =
        finishLinkResult ??
        Ok(
          AuthUser(
            id: UserId('user-1'),
            displayName: 'Nikolaos',
            isAnonymous: false,
            email: startLinkCalls.last,
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
SignIn aSignIn({bool hasProfile = true}) => (
  user: AuthUser(
    id: UserId('user-1'),
    displayName: 'Nikolaos',
    isAnonymous: true,
  ),
  hasProfile: hasProfile,
);
