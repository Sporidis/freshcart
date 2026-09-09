import 'package:freshcart_client/freshcart_client.dart' as dto;
// `client.auth` is an extension on the Serverpod client, not a generated member.
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

/// Makes sure the app has an identity before it calls anything.
///
/// Every FreshCart endpoint sets `requireLogin`, so without a session the very
/// first list fetch would come back unauthorized. FreshCart is anonymous-first
/// (`docs/decisions.md` #6): a user gets a stable `authUserId` on launch with no
/// signup form, and later *links* Google or email to that same id.
abstract final class AnonymousSessionBootstrap {
  /// Restores a stored session, or creates an anonymous one.
  ///
  /// Returns whether the app ended up authenticated. A `false` here is not
  /// fatal — the UI still renders and every call will report
  /// `Failure.unauthorized`, which is a far better failure mode than a crash on
  /// a cold start with no network.
  static Future<bool> ensureSignedIn(dto.Client client) async {
    await client.auth.initialize();
    if (client.auth.isAuthenticated) return true;

    try {
      // No token is passed: app attestation would be configured server-side via
      // onBeforeAnonymousAccountCreated, and this project does not use it. The
      // per-IP rate limit on AnonymousIdpConfig is the abuse guard instead.
      final session = await client.anonymousIdp.login();
      await client.auth.updateSignedInUser(session);
      return client.auth.isAuthenticated;
    } on Exception catch (_) {
      // Offline on first launch is the common case here. Swallowing it lets the
      // app boot and show its own error state rather than dying at startup.
      return false;
    }
  }
}
