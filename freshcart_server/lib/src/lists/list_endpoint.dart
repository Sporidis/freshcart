import 'package:freshcart_server/src/common/business/session_user.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/lists/business/list_service.dart';
import 'package:serverpod/serverpod.dart';

/// Endpoint for shopping lists: create, read, join, rename, leave, delete.
///
/// Kept small: each method gets the user and calls [ListService], where the
/// rules are.
class ListEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Every list the caller belongs to.
  Future<List<ShoppingList>> myLists(Session session) =>
      ListService.listsFor(session, session.requireUserId);

  /// One list the caller belongs to.
  Future<ShoppingList> byId(Session session, UuidValue listId) =>
      ListService.byId(session, listId, session.requireUserId);

  /// Item counts for the caller's lists in [listIds] (for the drawer).
  Future<List<ListSummary>> summaries(
    Session session,
    List<UuidValue> listIds,
  ) => ListService.summaries(session, listIds, session.requireUserId);

  /// Creates a list owned by the caller.
  Future<ShoppingList> create(Session session, String name) =>
      ListService.create(session, session.requireUserId, name);

  /// Joins the list matching [joinCode].
  Future<ShoppingList> join(Session session, String joinCode) =>
      ListService.join(session, session.requireUserId, joinCode);

  /// Renames a list the caller owns.
  Future<ShoppingList> rename(
    Session session,
    UuidValue listId,
    String name,
  ) => ListService.rename(session, listId, session.requireUserId, name);

  /// Sets whether a list removes checked items automatically when
  /// everything is checked.
  Future<ShoppingList> setClearCheckedAfterShopping(
    Session session,
    UuidValue listId,
    bool value,
  ) => ListService.setClearCheckedAfterShopping(
    session,
    listId,
    session.requireUserId,
    value,
  );

  /// Removes the caller from a list.
  Future<void> leave(Session session, UuidValue listId) =>
      ListService.leave(session, listId, session.requireUserId);

  /// Deletes a list the caller owns, for everyone on it.
  Future<void> delete(Session session, UuidValue listId) =>
      ListService.delete(session, listId, session.requireUserId);

  /// Removes another member from a list the caller owns.
  Future<void> removeMember(
    Session session,
    UuidValue listId,
    UuidValue userId,
  ) => ListService.removeMember(
    session,
    listId,
    session.requireUserId,
    userId,
  );

  /// Hands ownership of a list the caller owns to another member.
  Future<ShoppingList> transferOwnership(
    Session session,
    UuidValue listId,
    UuidValue userId,
  ) => ListService.transferOwnership(
    session,
    listId,
    session.requireUserId,
    userId,
  );

  /// Live updates to a list (its name and members).
  ///
  /// Sends the whole [ShoppingList] each time (it's one small row). This is
  /// for live updates while the app is open, not push notifications.
  Stream<ShoppingList> watchList(Session session, UuidValue listId) async* {
    await ListService.requireMembership(session, listId, session.requireUserId);
    yield* session.messages.createStream<ShoppingList>(
      ListService.channelFor(listId),
    );
  }
}
