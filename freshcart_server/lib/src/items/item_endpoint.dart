import 'package:freshcart_server/src/common/business/session_user.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/items/business/item_service.dart';
import 'package:freshcart_server/src/lists/business/list_service.dart';
import 'package:serverpod/serverpod.dart';

/// The items on a list: read, add, save, remove.
class ItemEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Every item on a list the caller belongs to.
  Future<List<ShoppingItem>> byList(Session session, UuidValue listId) =>
      ItemService.byList(session, listId, session.requireUserId);

  /// The quantity used when a caller does not specify one.
  static const int defaultQuantity = 1;

  /// Adds an item to a list the caller belongs to.
  ///
  /// [quantity] is nullable rather than defaulted because Serverpod's generator
  /// drops Dart default values and emits any non-nullable named parameter as
  /// `required`. Nullability is what makes a parameter optional in the
  /// generated client, so the default lives here instead.
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

  /// Writes an item back, rejecting the write on an optimistic-concurrency
  /// clash.
  Future<ShoppingItem> save(Session session, ShoppingItem item) =>
      ItemService.save(session, item, session.requireUserId);

  /// Deletes an item.
  Future<void> remove(Session session, UuidValue itemId) =>
      ItemService.remove(session, itemId, session.requireUserId);

  /// Deletes every checked item on the list, returning how many were removed.
  Future<int> clearChecked(Session session, UuidValue listId) =>
      ItemService.clearChecked(session, listId, session.requireUserId);

  /// Deletes a multi-selected set of items from the list in one operation,
  /// returning how many were removed.
  Future<int> removeMany(
    Session session,
    UuidValue listId,
    List<UuidValue> itemIds,
  ) => ItemService.removeMany(session, listId, session.requireUserId, itemIds);

  /// Product name suggestions for a list, matching [query], most recently
  /// used first -- the add control's suggestion chips.
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

  /// Live changes to a list's items.
  ///
  /// Emits a delta per change rather than the whole list — subscribers keep the
  /// merged state themselves. Membership is checked once, when the stream
  /// opens; the stream closes if the session ends.
  ///
  /// This is the in-app half of the two-layer story: it keeps open clients live
  /// and is unrelated to FCM background push, which covers closed apps.
  Stream<ItemChange> watchList(Session session, UuidValue listId) async* {
    await ListService.requireMembership(session, listId, session.requireUserId);
    yield* session.messages.createStream<ItemChange>(
      ItemService.channelFor(listId),
    );
  }
}
