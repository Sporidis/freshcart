import 'package:freshcart_domain/freshcart_domain.dart' as domain;
import 'package:freshcart_server/src/generated/protocol.dart';

/// Exposes a list row's invite columns as a [domain.ListInvite].
///
/// Lets the server apply the domain's expiry and reuse rules rather than
/// comparing the columns directly.
extension ShoppingListInvite on ShoppingList {
  /// The list's invite, or null if no invite has been opened or the row
  /// predates expiring invites.
  domain.ListInvite? get invite {
    final code = joinCode;
    final expiresAt = joinCodeExpiresAt;
    if (code == null || expiresAt == null) return null;
    final parsed = domain.JoinCode.parse(code).valueOrNull;
    if (parsed == null) return null;
    return domain.ListInvite(code: parsed, expiresAt: expiresAt);
  }
}
