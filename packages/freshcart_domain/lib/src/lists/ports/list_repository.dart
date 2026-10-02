import 'package:freshcart_domain/src/auth/value_objects/user_id.dart';
import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/lists/entities/list_summary.dart';
import 'package:freshcart_domain/src/lists/entities/shopping_list.dart';
import 'package:freshcart_domain/src/lists/value_objects/join_code.dart';
import 'package:freshcart_domain/src/lists/value_objects/list_id.dart';

/// The interface for reading and saving shopping lists.
///
/// This is a "port": the domain says WHAT it needs, and the app's `data/`
/// layer implements it with Serverpod. Nothing here mentions Serverpod, so
/// changing the backend only changes that implementation.
abstract interface class ListRepository {
  /// All lists the signed-in user is on.
  Future<Result<List<ShoppingList>>> myLists();

  /// One list by [id], or `Failure.notFound` if it's gone or you can't see
  /// it.
  Future<Result<ShoppingList>> byId(ListId id);

  /// Item counts for the lists [ids], for the drawer. May return fewer than
  /// [ids] if the user can't see some of them.
  Future<Result<List<ListSummary>>> summaries(List<ListId> ids);

  /// Creates a list called [name], owned by the signed-in user. The server
  /// creates the [JoinCode].
  Future<Result<ShoppingList>> create({required String name});

  /// Joins the list with [code]. The signed-in user becomes a member.
  Future<Result<ShoppingList>> joinByCode(JoinCode code);

  /// Renames list [id] to [name]. Owner only.
  Future<Result<ShoppingList>> rename(ListId id, String name);

  /// Sets whether list [id] removes checked items automatically when
  /// everything is checked (decisions.md #79).
  ///
  /// Any member can change this (not only the owner), like turning a shop
  /// tab on or off. It's a shared preference, not a dangerous action.
  Future<Result<ShoppingList>> setClearCheckedAfterShopping(
    ListId id,
    bool value,
  );

  /// Removes the signed-in user from list [id].
  Future<Result<void>> leave(ListId id);

  /// Deletes list [id] for everyone. Only the owner can.
  ///
  /// Separate from [leave] on purpose. Leaving only removes you; deleting
  /// removes the list for everyone. One method with a flag would make it
  /// too easy to delete a shared list by mistake.
  Future<Result<void>> delete(ListId id);

  /// Removes member [userId] from list [id]. Only the owner can.
  ///
  /// Different from [leave]: you leave yourself, but the owner removes
  /// someone else.
  Future<Result<void>> removeMember(ListId id, UserId userId);

  /// Makes member [userId] the owner of list [id]. The old owner becomes a
  /// normal member.
  ///
  /// This lets an owner leave without leaving a list that nobody can rename
  /// or delete.
  Future<Result<ShoppingList>> transferOwnership(ListId id, UserId userId);

  /// List [id], updated live whenever anyone changes it.
  ///
  /// If the connection drops, the implementation keeps the last value and
  /// reconnects by itself. Other errors (like "not found") come as `Err`.
  Stream<Result<ShoppingList>> watch(ListId id);
}
