import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

// `client.auth` comes from an extension in the import above.

/// Makes sure the user is signed in before the app calls the server.
///
/// Every server endpoint requires a login. FreshCart doesn't have a signup
/// form: on first launch the user gets an anonymous account automatically.
/// Later they can link an email (or Google) to that same account.
/// See decisions.md #6.
abstract final class AnonymousSessionBootstrap {
  /// Uses the saved session, or creates a new anonymous account.
  ///
  /// `authenticated` is false only if both failed (usually: first launch
  /// without internet). The app still opens, and server calls just return
  /// "unauthorized". Much better than crashing.
  ///
  /// `isNewAccount` is true only if a new account was just created. That's
  /// how we know to show onboarding, without saving a separate flag.
  static Future<({bool authenticated, bool isNewAccount})> ensureSignedIn(
    dto.Client client,
  ) async {
    await client.auth.initialize();
    if (client.auth.isAuthenticated) {
      return (authenticated: true, isNewAccount: false);
    }

    try {
      // No token needed. Spam protection is done on the server, by limiting
      // how many accounts one IP address can create.
      final session = await client.anonymousIdp.login();
      await client.auth.updateSignedInUser(session);
      final authenticated = client.auth.isAuthenticated;
      return (authenticated: authenticated, isNewAccount: authenticated);
    } on Exception catch (_) {
      // Usually: no internet on first launch. Catch it so the app still
      // opens and can show its own error, instead of crashing.
      return (authenticated: false, isNewAccount: false);
    }
  }
}
