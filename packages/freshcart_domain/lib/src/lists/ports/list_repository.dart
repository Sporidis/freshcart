import 'package:freshcart_domain/src/auth/value_objects/user_id.dart';
import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/lists/entities/list_summary.dart';
import 'package:freshcart_domain/src/lists/entities/shopping_list.dart';
import 'package:freshcart_domain/src/lists/value_objects/join_code.dart';
import 'package:freshcart_domain/src/lists/value_objects/list_id.dart';

/// How the domain reads and writes shopping lists.
///
/// A *port*: the domain declares the shape, `freshcart_flutter`'s `data/` layer
/// supplies the implementation against the Serverpod client. Nothing here
/// mentions transport, so swapping the backend touches only that adapter.
abstract interface class ListRepository {
  /// Every list the signed-in user belongs to.
  Future<Result<List<ShoppingList>>> myLists();

  /// One list by [id], or `Failure.notFound` if it is gone or not visible.
  Future<Result<ShoppingList>> byId(ListId id);

  /// Item counts for each of [ids] the signed-in user belongs to -- the
  /// drawer's remaining-count row (Flow 10, §4). May return fewer entries
  /// than [ids] if some are not visible to the caller.
  Future<Result<List<ListSummary>>> summaries(List<ListId> ids);

  /// Creates a list named [name], owned by the signed-in user.
  ///
  /// The server generates the [JoinCode].
  Future<Result<ShoppingList>> create({required String name});

  /// Joins the list matching [code], adding the signed-in user as a member.
  Future<Result<ShoppingList>> joinByCode(JoinCode code);

  /// Renames list [id] to [name]. Owner only.
  Future<Result<ShoppingList>> rename(ListId id, String name);

  /// Sets whether list [id] clears its checked items automatically once
  /// everything on it is checked (decisions #79). Any member may set this --
  /// unlike rename/delete, it is a shared shopping-behaviour preference, not
  /// an identity or destructive action, matching how any member may already
  /// toggle a shop's `isActive`.
  Future<Result<ShoppingList>> setClearCheckedAfterShopping(
    ListId id,
    bool value,
  );

  /// Removes the signed-in user from list [id].
  Future<Result<void>> leave(ListId id);

  /// Deletes list [id] for everyone on it.
  ///
  /// Distinct from [leave] on purpose. Leaving takes you out of a list that
  /// carries on without you; this ends it for the whole household, and only
  /// its owner may do it. Collapsing the two into one call with a flag is how
  /// somebody destroys a shared list meaning to walk away from it.
  Future<Result<void>> delete(ListId id);

  /// Removes [userId] from list [id], on the owner's authority.
  ///
  /// Not the same as [leave]: leaving is something you do to yourself,
  /// removal is something done to you, and only the list's owner may do it.
  Future<Result<void>> removeMember(ListId id, UserId userId);

  /// Hands ownership of list [id] to [userId], who must already be a member.
  ///
  /// The outgoing owner becomes an ordinary member. This is the honest way
  /// out for an owner who wants to leave — the alternative would be a list
  /// nobody can rename or delete.
  Future<Result<ShoppingList>> transferOwnership(ListId id, UserId userId);

  /// Live view of list [id], re-emitting whenever anyone changes it.
  ///
  /// Backed by a Serverpod stream (Phase 8). Emits `Err` for a transport drop
  /// rather than closing, so the UI can show a reconnecting state instead of
  /// going blank.
  Stream<Result<ShoppingList>> watch(ListId id);
}
