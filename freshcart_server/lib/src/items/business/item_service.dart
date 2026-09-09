import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/lists/business/list_service.dart';
import 'package:freshcart_server/src/notifications/business/notification_service.dart';
import 'package:freshcart_server/src/users/business/profile_service.dart';
import 'package:serverpod/serverpod.dart';

/// Business operations on the items of a list.
abstract final class ItemService {
  /// The message channel carrying changes for one list.
  ///
  /// Per list, not global: a client watching one list should not be woken by
  /// traffic on every other list on the server.
  static String channelFor(UuidValue listId) => 'list-items-$listId';

  /// Broadcasts a change to everyone watching [listId], and buffers it for a
  /// background push.
  ///
  /// Two layers, on purpose: the stream reaches clients that have the app
  /// **open**, the buffered push reaches those that do not. Fire-and-forget by
  /// design — a dropped notification must never fail the write that caused it.
  static Future<void> _announce(
    Session session,
    UuidValue listId,
    ItemChange change, {
    required String itemName,
  }) async {
    await session.messages.postMessage(channelFor(listId), change);
    await NotificationService.enqueue(
      session,
      listId: listId,
      actorId: change.actorId,
      actorName: await ProfileService.displayNameFor(session, change.actorId),
      itemName: itemName,
      kind: change.kind,
    );
  }

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
    final inserted = await ShoppingItem.db.insertRow(
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
    await _announce(
      session,
      listId,
      ItemChange(
        kind: ItemChangeKind.upserted,
        itemId: inserted.id!,
        item: inserted,
        actorId: userId,
      ),
      itemName: inserted.name,
    );
    return inserted;
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

      final saved = await ShoppingItem.db.updateRow(
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
      await _announce(
        session,
        stored.listId,
        ItemChange(
          kind: ItemChangeKind.upserted,
          itemId: saved.id!,
          item: saved,
          actorId: userId,
        ),
        itemName: saved.name,
      );
      return saved;
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
    await _announce(
      session,
      stored.listId,
      ItemChange(
        kind: ItemChangeKind.removed,
        itemId: stored.id!,
        actorId: userId,
      ),
      itemName: stored.name,
    );
  }
}
