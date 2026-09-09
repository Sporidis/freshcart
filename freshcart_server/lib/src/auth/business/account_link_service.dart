import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';

/// Attaches credentials to an *existing* account.
///
/// This is the mechanism `docs/decisions.md` #6 rests on: a user starts
/// anonymous, and later linking Google or email keeps the same `authUserId`, so
/// every list and item they created stays attached with no migration.
///
/// Serverpod 3.4's anonymous provider ships **without** first-class account
/// linking — its own changelog says so. What it does ship is the admin
/// primitive: `EmailIdpAdmin.createEmailAuthentication` takes an existing
/// `authUserId`. Linking is therefore implemented here on top of that, rather
/// than waiting for upstream (`docs/decisions.md` #39).
abstract final class AccountLinkService {
  /// Attaches an email/password credential to [authUserId].
  ///
  /// Throws [AccountAlreadyLinkedException] if this account already has an
  /// email credential — linking twice would leave two ways in and no way to
  /// reason about which is current.
  static Future<void> linkEmail(
    Session session,
    UuidValue authUserId, {
    required String email,
    required String password,
  }) async {
    final existing = await EmailAccount.db.findFirstRow(
      session,
      where: (t) => t.authUserId.equals(authUserId),
    );
    if (existing != null) throw AccountAlreadyLinkedException();

    // If this email already belongs to someone else, refuse rather than
    // silently attaching it — that would be account takeover.
    final claimed = await EmailAccount.db.findFirstRow(
      session,
      where: (t) => t.email.equals(email.toLowerCase()),
    );
    if (claimed != null) throw EmailAlreadyInUseException();

    await AuthServices.instance.emailIdp.admin.createEmailAuthentication(
      session,
      authUserId: authUserId,
      email: email,
      password: password,
    );
  }

  /// Which providers are attached to [authUserId].
  ///
  /// An account with none is still anonymous, which is what the app uses to
  /// decide whether to nudge an upgrade.
  static Future<List<LinkedProvider>> linkedProviders(
    Session session,
    UuidValue authUserId,
  ) async {
    final email = await EmailAccount.db.findFirstRow(
      session,
      where: (t) => t.authUserId.equals(authUserId),
    );
    final google = await GoogleAccount.db.findFirstRow(
      session,
      where: (t) => t.authUserId.equals(authUserId),
    );

    return [
      if (email != null) LinkedProvider.email,
      if (google != null) LinkedProvider.google,
      if (email == null && google == null) LinkedProvider.anonymous,
    ];
  }

  /// Whether [authUserId] would survive losing this device.
  static Future<bool> isRecoverable(
    Session session,
    UuidValue authUserId,
  ) async {
    final providers = await linkedProviders(session, authUserId);
    return !providers.contains(LinkedProvider.anonymous);
  }
}
