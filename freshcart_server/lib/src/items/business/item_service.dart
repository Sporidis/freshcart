import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/lists/business/list_service.dart';
import 'package:serverpod/serverpod.dart';

/// Business operations on the items of a list.
abstract final class ItemService {
  /// Every item on [listId], oldest first, for a caller who belongs to it.
  static Future<List<ShoppingItem>> byList(
    Session session,
    UuidValue listId,
    UuidValue userId,
  ) async {
    await ListService.requireMembership(session, listId, userId);
    return ShoppingItem.db.find(
      session,
      where: (t) => t.listId.equals(listId),
      orderBy: (t) => t.createdAt,
    );
  }

  /// Appends an item to [listId].
  static Future<ShoppingItem> add(
    Session session,
    UuidValue listId,
    UuidValue userId, {
    required String name,
    required int quantity,
    UuidValue? shopId,
    String? noteText,
  }) async {
    await ListService.requireMembership(session, listId, userId);
    final now = DateTime.now().toUtc();
    return ShoppingItem.db.insertRow(
      session,
      ShoppingItem(
        listId: listId,
        name: name,
        quantity: quantity,
        isChecked: false,
        shopId: shopId,
        note: noteText == null
            ? null
            : Note(text: noteText, authorId: userId, updatedAt: now),
        addedBy: userId,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Writes [incoming] back, refusing the write if someone else got there
  /// first.
  ///
  /// The optimistic-concurrency check is the whole point of this method: the
  /// client sends the `updatedAt` it last saw, and if the stored row has since
  /// moved on we throw [EditConflictException] rather than silently discarding
  /// the other person's change. Two people editing one shopping list at the
  /// same time is the normal case here, not an edge case.
  static Future<ShoppingItem> save(
    Session session,
    ShoppingItem incoming,
    UuidValue userId,
  ) async {
    return session.db.transaction((transaction) async {
      final stored = await ShoppingItem.db.findById(
        session,
        incoming.id!,
        transaction: transaction,
      );
      if (stored == null) throw ItemNotFoundException();
      await ListService.requireMembership(session, stored.listId, userId);

      if (!stored.updatedAt.isAtSameMomentAs(incoming.updatedAt)) {
        throw EditConflictException();
      }

      // listId, addedBy and createdAt are server-owned: a client cannot move an
      // item to another list or rewrite its provenance by editing a field.
      //
      // The check attribution is server-owned too. The client says *whether*
      // the item is checked; the server decides *who* checked it and *when*,
      // from the session. Otherwise any member could attribute their tick to
      // someone else, and the "checked off by" label would be unreliable —
      // which on a shared list is the one thing it must not be.
      final now = DateTime.now().toUtc();
      final becameChecked = incoming.isChecked && !stored.isChecked;
      final becameUnchecked = !incoming.isChecked && stored.isChecked;

      return ShoppingItem.db.updateRow(
        session,
        incoming.copyWith(
          listId: stored.listId,
          addedBy: stored.addedBy,
          createdAt: stored.createdAt,
          updatedAt: now,
          checkedBy: switch ((becameChecked, becameUnchecked)) {
            (true, _) => userId,
            (_, true) => null,
            _ => stored.checkedBy,
          },
          checkedAt: switch ((becameChecked, becameUnchecked)) {
            (true, _) => now,
            (_, true) => null,
            _ => stored.checkedAt,
          },
        ),
        transaction: transaction,
      );
    });
  }

  /// Deletes an item, if the caller belongs to its list.
  static Future<void> remove(
    Session session,
    UuidValue itemId,
    UuidValue userId,
  ) async {
    final stored = await ShoppingItem.db.findById(session, itemId);
    if (stored == null) throw ItemNotFoundException();
    await ListService.requireMembership(session, stored.listId, userId);
    await ShoppingItem.db.deleteRow(session, stored);
  }
}
