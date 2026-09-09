import 'package:serverpod_auth_idp_server/providers/anonymous.dart';

/// Exposes the anonymous identity provider to clients.
///
/// FreshCart is anonymous-first: a user gets a stable `authUserId` on first
/// launch with no signup form, and Google/email are *linked* to that same id
/// later (`docs/decisions.md` #6). Every endpoint sets `requireLogin`, so
/// without this the app could not call anything at all.
///
/// Extending the base endpoint is what publishes it — the Flutter side looks
/// the endpoint up by type and fails loudly if a server has not exposed it.
class AnonymousIdpEndpoint extends AnonymousIdpBaseEndpoint {}
