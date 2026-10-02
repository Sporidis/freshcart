import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

/// Gets the logged-in user from a [Session].
extension SessionUser on Session {
  /// The caller's user id.
  ///
  /// The `!` is safe: every endpoint using this requires login, so requests
  /// without login are rejected before we get here. A null would be a bug,
  /// and then throwing is right.
  UuidValue get requireUserId => authenticated!.authUserId;
}
