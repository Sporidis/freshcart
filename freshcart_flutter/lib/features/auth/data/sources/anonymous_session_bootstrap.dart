import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_flutter/core/di/serverpod_client_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

part 'anonymous_session_bootstrap.g.dart';

// `client.auth` is an extension on the Serverpod client, not a generated member.

/// Makes sure the app has an identity before it calls anything.
///
/// Every FreshCart endpoint sets `requireLogin`, so without a session the very
/// first list fetch would come back unauthorized. FreshCart is anonymous-first
/// (`docs/decisions.md` #6): a user gets a stable `authUserId` on launch with no
/// signup form, and later *links* Google or email to that same id.
abstract final class AnonymousSessionBootstrap {
  /// Restores a stored session, or creates an anonymous one.
  ///
  /// `authenticated` is false only if both restoring and creating a session
  /// failed (typically offline on a first launch) — the UI still renders and
  /// every call will report `Failure.unauthorized`, which is a far better
  /// failure mode than a crash on a cold start with no network.
  ///
  /// `isNewIdentity` is true only when this call *created* the account rather
  /// than restoring one already on the device. `main()` cannot ask "has this
  /// person seen onboarding?" any other way without inventing a second,
  /// persisted flag that could drift from reality — this branch is the one
  /// place that already knows the answer.
  static Future<({bool authenticated, bool isNewIdentity})> ensureSignedIn(
    dto.Client client,
  ) async {
    await client.auth.initialize();
    if (client.auth.isAuthenticated) {
      return (authenticated: true, isNewIdentity: false);
    }

    try {
      // No token is passed: app attestation would be configured server-side via
      // onBeforeAnonymousAccountCreated, and this project does not use it. The
      // per-IP rate limit on AnonymousIdpConfig is the abuse guard instead.
      final session = await client.anonymousIdp.login();
      await client.auth.updateSignedInUser(session);
      final authenticated = client.auth.isAuthenticated;
      return (authenticated: authenticated, isNewIdentity: authenticated);
    } on Exception catch (_) {
      // Offline on first launch is the common case here. Swallowing it lets the
      // app boot and show its own error state rather than dying at startup.
      return (authenticated: false, isNewIdentity: false);
    }
  }
}

/// Signs the app in — restoring a stored session, or creating an anonymous
/// one — and reports whether the result is a brand-new identity.
///
/// A real async provider, not a value resolved before `runApp` and injected
/// through a `ProviderContainer` override: `main()` no longer awaits this at
/// all, so the first frame paints immediately and `SplashScreen` (watching
/// this provider) is what actually covers the wait — for exactly as long as
/// it takes, never artificially longer, matching the Splash frame in
/// `docs/multi-shop-shopping-list-app`. `main()` still kicks the request off
/// eagerly right after building the container (`ref.read(...future)`), so
/// the network round trip starts before the first frame even paints, rather
/// than waiting on Splash's own `build()` to ask for it.
@Riverpod(keepAlive: true)
Future<({bool authenticated, bool isNewIdentity})> authBootstrap(
  Ref ref,
) => AnonymousSessionBootstrap.ensureSignedIn(
  ref.watch(serverpodClientProvider),
);
