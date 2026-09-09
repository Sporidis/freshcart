import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:freshcart_domain/src/auth/value_objects/user_id.dart';

part 'auth_user.freezed.dart';

/// The signed-in identity.
///
/// FreshCart is anonymous-first: a user gets an [id] on first launch without
/// signing up, and later *links* Google or email to that same [id]. The id
/// never changes on upgrade, which is why no data migration is needed
/// (`docs/decisions.md` #6).
@freezed
abstract class AuthUser with _$AuthUser {
  /// Creates an authenticated user.
  const factory AuthUser({
    required UserId id,
    required String displayName,
    required bool isAnonymous,
    String? email,
  }) = _AuthUser;

  const AuthUser._();

  /// Whether this account would survive losing the current device.
  ///
  /// An anonymous session lives only in local storage: lose it and you lose
  /// access to every shared list. The UI uses this to nudge an upgrade at the
  /// moment it matters — creating or joining a shared list.
  bool get isRecoverable => !isAnonymous;
}
