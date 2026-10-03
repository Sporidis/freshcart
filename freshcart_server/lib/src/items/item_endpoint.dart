import 'package:freshcart_server/src/common/business/session_user.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/items/business/item_service.dart';
import 'package:freshcart_server/src/lists/business/list_service.dart';
import 'package:serverpod/serverpod.dart';

/// Endpoint for items on a list: read, add, save, delete.
class ItemEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// All items on a list (the caller must be a member).
  Future<List<ShoppingItem>> byList(Session session, UuidValue listId) =>
      ItemService.byList(session, listId, session.requireUserId);

  /// The quantity used when none is given.
  static const int defaultQuantity = 1;

  /// Adds an item to a list (the caller must be a member).
  ///
  /// [quantity] is nullable instead of having a default value, because
  /// Serverpod's generated client ignores defaults and makes every
  /// non-null parameter required. So the default is applied here.
  Future<ShoppingItem> add(
    Session session,
    UuidValue listId,
    String name, {
    int? quantity,
    UuidValue? shopId,
    String? noteText,
  }) => ItemService.add(
    session,
    listId,
    session.requireUserId,
    name: name,
    quantity: quantity ?? defaultQuantity,
    shopId: shopId,
    noteText: noteText,
  );

  /// Saves an item. Fails with a conflict if someone else changed it first.
  Future<ShoppingItem> save(Session session, ShoppingItem item) =>
      ItemService.save(session, item, session.requireUserId);

  /// Deletes an item.
  Future<void> remove(Session session, UuidValue itemId) =>
      ItemService.remove(session, itemId, session.requireUserId);

  /// Deletes all checked items on the list. Returns how many.
  Future<int> clearChecked(Session session, UuidValue listId) =>
      ItemService.clearChecked(session, listId, session.requireUserId);

  /// Deletes the selected items (all at once). Returns how many.
  Future<int> removeMany(
    Session session,
    UuidValue listId,
    List<UuidValue> itemIds,
  ) => ItemService.removeMany(session, listId, session.requireUserId, itemIds);

  /// Moves [itemIds] to [shopId] (null = no shop), all at once. Returns how
  /// many.
  Future<int> moveMany(
    Session session,
    UuidValue listId,
    List<UuidValue> itemIds,
    UuidValue? shopId,
  ) => ItemService.moveMany(
    session,
    listId,
    session.requireUserId,
    itemIds,
    shopId,
  );

  /// Name suggestions for a list that match [query], newest first.
  Future<List<String>> suggestNames(
    Session session,
    UuidValue listId,
    String query,
  ) => ItemService.suggestNames(
    session,
    listId,
    session.requireUserId,
    query,
  );

  /// Every item name ever used on a list, newest first ("Recently bought").
  Future<List<ItemNameHistory>> recentNames(
    Session session,
    UuidValue listId,
  ) => ItemService.recentNames(session, listId, session.requireUserId);

  /// Live updates to a list's items.
  ///
  /// Sends only what changed (not the whole list); the app applies it.
  /// Membership is checked once, when the stream starts. The stream stops
  /// if the session ends.
  ///
  /// This is for live updates while the app is open, not push
  /// notifications (those are for a closed app).
  Stream<ItemChange> watchList(Session session, UuidValue listId) async* {
    await ListService.requireMembership(session, listId, session.requireUserId);
    yield* session.messages.createStream<ItemChange>(
      ItemService.channelFor(listId),
    );
  }
}
