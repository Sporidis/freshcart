import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/auth/application/providers/signed_in_user_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'list_membership_provider.g.dart';

/// The signed-in user's own membership of [list], or null until the
/// identity resolves.
@riverpod
ListMember? myMembership(Ref ref, ShoppingList list) {
  final me = ref.watch(signedInUserIdProvider);
  return me == null ? null : list.memberFor(me);
}

/// Whether the signed-in user owns [list].
///
/// False until the identity resolves: assuming membership rather than
/// ownership means the reversible action (leave) is what gets offered in
/// the meantime, never the destructive one (delete for everyone).
@riverpod
bool isListOwner(Ref ref, ShoppingList list) {
  final me = ref.watch(signedInUserIdProvider);
  return me != null && list.isOwnedBy(me);
}
