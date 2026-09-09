import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

/// Reads the caller's identity off an authenticated [Session].
extension SessionUser on Session {
  /// The caller's stable auth user id.
  ///
  /// Safe to force here: every endpoint that calls it sets `requireLogin`, so
  /// an unauthenticated request is rejected before the method body runs. A null
  /// at this point would be a wiring bug, which is exactly what should throw.
  UuidValue get requireUserId => authenticated!.authUserId;
}
