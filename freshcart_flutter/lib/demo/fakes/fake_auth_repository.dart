import 'dart:typed_data';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/demo/demo_backend.dart';

/// [AuthRepository] for one demo phone. The user lives in `db.users[me]`, which
/// the demo seeds before the phone starts.
///
/// Anything that needs a real account (linking, photos, signing out) fails
/// with a clear message instead of pretending to work.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._db, this._me);

  final DemoBackend _db;
  final UserId _me;

  static const _unavailable = Failure.unexpected('Not available in the demo');

  @override
  AuthUser? get currentUser => _db.users[_me];

  @override
  Stream<AuthUser?> authStateChanges() => _db.watch(() => currentUser);

  @override
  Future<Result<SignIn>> ensureSignedIn() async {
    await _db.latency();
    return switch (currentUser) {
      // A persona without a name hasn't been through onboarding yet.
      final user? => Ok((user: user, hasProfile: user.displayName.isNotEmpty)),
      null => const Err(Failure.unauthorized()),
    };
  }

  @override
  Future<Result<AuthUser>> setDisplayName(String displayName) async {
    await _db.latency();
    return _update(
      (user) => user.copyWith(displayName: displayName),
      (member) => member.copyWith(displayName: displayName),
    );
  }

  @override
  Future<Result<AuthUser>> setAvatarColor(HexColor color) async {
    await _db.latency();
    return _update(
      (user) => user.copyWith(avatarColor: color),
      (member) => member.copyWith(avatarColor: color),
    );
  }

  @override
  Future<Result<AuthUser>> setAvatarPhoto(Uint8List bytes) async =>
      const Err(_unavailable);

  @override
  Future<Result<AuthUser>> clearAvatarPhoto() async {
    await _db.latency();
    // The demo never has a photo, so there is nothing to clear.
    return switch (currentUser) {
      final user? => Ok(user),
      null => const Err(Failure.unauthorized()),
    };
  }

  @override
  Future<Result<AuthUser>> linkGoogle() async => const Err(_unavailable);

  @override
  Future<Result<String>> startLinkEmail(String email) async =>
      const Err(_unavailable);

  @override
  Future<Result<AuthUser>> finishLinkEmail({
    required String requestId,
    required String code,
    required String password,
  }) async => const Err(_unavailable);

  /// Blocked: an anonymous demo phone could never sign back in.
  @override
  Future<Result<void>> signOut() async => const Err(_unavailable);

  /// Changes the user, and their member record on every list, so the other
  /// phone sees the new profile (the real server fills members in on read).
  Result<AuthUser> _update(
    AuthUser Function(AuthUser) changeUser,
    ListMember Function(ListMember) changeMember,
  ) {
    final user = currentUser;
    if (user == null) return const Err(Failure.unauthorized());
    final updated = changeUser(user);
    _db.users[_me] = updated;
    for (final list in _db.lists.values.toList()) {
      if (!list.hasMember(_me)) continue;
      _db.lists[list.id] = list.copyWith(
        members: [
          for (final m in list.members)
            if (m.userId == _me) changeMember(m) else m,
        ],
      );
    }
    _db.notify();
    return Ok(updated);
  }
}
