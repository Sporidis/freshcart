import 'dart:async';

import 'package:freshcart_domain/freshcart_domain.dart';

/// An in-memory [AuthPort] for presentation tests.
class FakeAuthRepository implements AuthPort {
  /// The identity [signInAnonymously] and the link calls resolve to.
  Result<AuthUser> user = Ok(
    AuthUser(id: UserId('user-1'), displayName: 'Nikolaos', isAnonymous: true),
  );

  /// What [linkEmail] returns. Defaults to succeeding and clearing anonymity.
  Result<AuthUser>? linkResult;

  /// Credentials passed to [linkEmail], in order.
  final List<({String email, String password})> linkCalls = [];

  final StreamController<AuthUser?> _changes =
      StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? get currentUser => user.valueOrNull;

  @override
  Stream<AuthUser?> authStateChanges() => _changes.stream;

  @override
  Future<Result<AuthUser>> signInAnonymously() async => user;

  @override
  Future<Result<AuthUser>> setDisplayName(String displayName) async => user;

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
    Failure.validation('google', 'Google sign-in is not configured'),
  );

  @override
  Future<Result<void>> signOut() async => const Ok<void>(null);

  /// Closes the change stream. Call from a test teardown.
  Future<void> dispose() => _changes.close();
}
