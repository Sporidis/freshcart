import 'package:freshcart_server/src/common/business/session_user.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/lists/business/list_service.dart';
import 'package:freshcart_server/src/users/business/profile_service.dart';
import 'package:serverpod/serverpod.dart';

/// Shopping lists: create, read, join, rename, leave, delete.
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

  /// Item counts for each of [listIds] the caller belongs to -- the
  /// drawer's remaining-count row.
  Future<List<ListSummary>> summaries(
    Session session,
    List<UuidValue> listIds,
  ) => ListService.summaries(session, listIds, session.requireUserId);

  /// Creates a list owned by the caller.
  Future<ShoppingList> create(Session session, String name) async {
    final userId = session.requireUserId;
    return ListService.create(
      session,
      userId,
      name,
      await ProfileService.displayNameFor(session, userId),
      await ProfileService.avatarColorArgbFor(session, userId),
      await ProfileService.avatarPhotoUrlFor(session, userId),
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
      await ProfileService.avatarColorArgbFor(session, userId),
      await ProfileService.avatarPhotoUrlFor(session, userId),
    );
  }

  /// Renames a list the caller owns.
  Future<ShoppingList> rename(
    Session session,
    UuidValue listId,
    String name,
  ) => ListService.rename(session, listId, session.requireUserId, name);

  /// Sets whether a list the caller belongs to clears its checked items
  /// automatically once everything on it is checked.
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
