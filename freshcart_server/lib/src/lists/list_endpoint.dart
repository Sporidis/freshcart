import 'package:freshcart_server/src/common/business/session_user.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/lists/business/list_service.dart';
import 'package:freshcart_server/src/users/business/profile_service.dart';
import 'package:serverpod/serverpod.dart';

/// Shopping lists: create, read, join, rename, leave.
///
/// Thin by design — every method resolves the caller and hands straight off to
/// [ListService], which is where the rules and the transactions live.
class ListEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Every list the caller belongs to.
  Future<List<ShoppingList>> myLists(Session session) =>
      ListService.listsFor(session, session.requireUserId);

  /// One list the caller belongs to.
  Future<ShoppingList> byId(Session session, UuidValue listId) =>
      ListService.byId(session, listId, session.requireUserId);

  /// Creates a list owned by the caller.
  Future<ShoppingList> create(Session session, String name) async {
    final userId = session.requireUserId;
    return ListService.create(
      session,
      userId,
      name,
      await ProfileService.displayNameFor(session, userId),
    );
  }

  /// Joins the list matching [joinCode].
  Future<ShoppingList> join(Session session, String joinCode) async {
    final userId = session.requireUserId;
    return ListService.join(
      session,
      userId,
      joinCode,
      await ProfileService.displayNameFor(session, userId),
    );
  }

  /// Renames a list the caller owns.
  Future<ShoppingList> rename(
    Session session,
    UuidValue listId,
    String name,
  ) => ListService.rename(session, listId, session.requireUserId, name);

  /// Removes the caller from a list.
  Future<void> leave(Session session, UuidValue listId) =>
      ListService.leave(session, listId, session.requireUserId);

  /// Live changes to a list itself — its name and its membership.
  ///
  /// Sends the whole [ShoppingList], not a delta: unlike items, a list is a
  /// single row, so there is nothing to merge. This is the in-app half of the
  /// two-layer story, same as [ItemEndpoint.watchList] — it keeps open clients
  /// live and is unrelated to FCM background push.
  Stream<ShoppingList> watchList(Session session, UuidValue listId) async* {
    await ListService.requireMembership(session, listId, session.requireUserId);
    yield* session.messages.createStream<ShoppingList>(
      ListService.channelFor(listId),
    );
  }
}
