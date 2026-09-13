// Aliased: this file's own ShoppingItem (below) is the generated Serverpod
// model, and the domain package's entity of the same name is only reached
// for sortOrderGap -- the one constant that has to agree with the pure
// midpoint arithmetic in ShoppingItem.sortOrderBetween on the client.
import 'package:freshcart_domain/freshcart_domain.dart' as domain;
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

  /// Every item on [listId], in manual sort order (ties -- everything
  /// predating the sortOrder column shares the same default -- broken by
  /// creation order), for a caller who belongs to it.
  static Future<List<ShoppingItem>> byList(
    Session session,
    UuidValue listId,
    UuidValue userId,
  ) async {
    await ListService.requireMembership(session, listId, userId);
    return ShoppingItem.db.find(
      session,
      where: (t) => t.listId.equals(listId),
      orderByList: (t) => [
        Order(column: t.sortOrder),
        Order(column: t.createdAt),
      ],
    );
  }

  /// The sortOrder that appends past the current end of [listId], for a
  /// freshly-added item.
  ///
  /// A read-then-write rather than a single `MAX(sortOrder)` SQL expression:
  /// Serverpod's query builder has no aggregate-function escape hatch short
  /// of raw SQL, and one extra indexed lookup on `add` -- not a hot path --
  /// is a smaller cost than hand-writing SQL for it.
  static Future<double> _appendSortOrder(
    Session session,
    UuidValue listId,
  ) async {
    final last = await ShoppingItem.db.findFirstRow(
      session,
      where: (t) => t.listId.equals(listId),
      orderBy: (t) => t.sortOrder,
      orderDescending: true,
    );
    return (last?.sortOrder ?? 0) + domain.ShoppingItem.sortOrderGap;
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
        sortOrder: await _appendSortOrder(session, listId),
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
    // Best-effort bookkeeping for suggestions -- must never fail the add
    // itself, the same reasoning as _announce's own fire-and-forget push.
    try {
      await _recordNameHistory(session, listId, name);
    } on Object catch (_) {
      // Swallowed on purpose: the item was already added successfully.
    }
    return inserted;
  }

  /// Records that [name] was just added to [listId], so it can be suggested
  /// again later -- upserts rather than always inserting, since the unique
  /// index on (listId, name) means a repeat add updates [lastUsedAt] on the
  /// existing row instead of failing on the constraint.
  static Future<void> _recordNameHistory(
    Session session,
    UuidValue listId,
    String name,
  ) async {
    final now = DateTime.now().toUtc();
    final existing = await ItemNameHistory.db.findFirstRow(
      session,
      where: (t) => t.listId.equals(listId) & t.name.equals(name),
    );
    if (existing == null) {
      await ItemNameHistory.db.insertRow(
        session,
        ItemNameHistory(listId: listId, name: name, lastUsedAt: now),
      );
    } else {
      await ItemNameHistory.db.updateRow(
        session,
        existing.copyWith(lastUsedAt: now),
      );
    }
  }

  /// Product names typed on [listId] before, matching [query], most
  /// recently used first -- the add control's suggestion chips.
  ///
  /// Empty for anything under two characters: matching against one letter
  /// would surface most of a list's history at once, which is noise, not a
  /// suggestion.
  static Future<List<String>> suggestNames(
    Session session,
    UuidValue listId,
    UuidValue userId,
    String query, {
    int limit = 5,
  }) async {
    await ListService.requireMembership(session, listId, userId);
    final trimmed = query.trim();
    if (trimmed.length < 2) return const [];
    final rows = await ItemNameHistory.db.find(
      session,
      where: (t) => t.listId.equals(listId) & t.name.ilike('%$trimmed%'),
      orderBy: (t) => t.lastUsedAt,
      orderDescending: true,
      limit: limit,
    );
    return [for (final row in rows) row.name];
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

  /// Deletes every checked item on [listId] in one operation, returning how
  /// many were removed.
  ///
  /// One transaction, not a loop of [remove] calls: a client tapping "Clear
  /// checked" means all of them or a clear failure, never half a trolley
  /// silently left behind because the third delete happened to fail.
  static Future<int> clearChecked(
    Session session,
    UuidValue listId,
    UuidValue userId,
  ) async {
    await ListService.requireMembership(session, listId, userId);
    return session.db.transaction((transaction) async {
      final removed = await ShoppingItem.db.deleteWhere(
        session,
        where: (t) => t.listId.equals(listId) & t.isChecked.equals(true),
        transaction: transaction,
      );
      for (final item in removed) {
        await _announce(
          session,
          listId,
          ItemChange(
            kind: ItemChangeKind.removed,
            itemId: item.id!,
            actorId: userId,
          ),
          itemName: item.name,
        );
      }
      return removed.length;
    });
  }

  /// Deletes exactly the items in [itemIds] that belong to [listId], in one
  /// operation, returning how many were removed.
  ///
  /// One transaction, not a loop of [remove] calls, for the same reason as
  /// [clearChecked]: a multi-select "Delete" is one promise ("these, all of
  /// them"), and a loop can fail partway through and leave the selection half
  /// gone with nothing clean to report. Scoped to [listId] so a stale or
  /// tampered id from another list can only fail to match, never delete
  /// something the caller does not have through this list.
  static Future<int> removeMany(
    Session session,
    UuidValue listId,
    UuidValue userId,
    List<UuidValue> itemIds,
  ) async {
    await ListService.requireMembership(session, listId, userId);
    if (itemIds.isEmpty) return 0;
    return session.db.transaction((transaction) async {
      final removed = await ShoppingItem.db.deleteWhere(
        session,
        where: (t) => t.listId.equals(listId) & t.id.inSet(itemIds.toSet()),
        transaction: transaction,
      );
      for (final item in removed) {
        await _announce(
          session,
          listId,
          ItemChange(
            kind: ItemChangeKind.removed,
            itemId: item.id!,
            actorId: userId,
          ),
          itemName: item.name,
        );
      }
      return removed.length;
    });
  }

  /// Reassigns every item in [itemIds] that belongs to [listId] to [shopId]
  /// (null untags them), in one transaction, returning how many moved.
  ///
  /// One transaction, not a loop of individual saves -- same reasoning as
  /// [removeMany]: a multi-select "Move" is one promise ("these, all of
  /// them, to this shop"), and a loop that fails partway through would leave
  /// the selection split across two shops with nothing clean to report.
  static Future<int> moveMany(
    Session session,
    UuidValue listId,
    UuidValue userId,
    List<UuidValue> itemIds,
    UuidValue? shopId,
  ) async {
    await ListService.requireMembership(session, listId, userId);
    if (itemIds.isEmpty) return 0;
    return session.db.transaction((transaction) async {
      final existing = await ShoppingItem.db.find(
        session,
        where: (t) => t.listId.equals(listId) & t.id.inSet(itemIds.toSet()),
        transaction: transaction,
      );
      final moved = await ShoppingItem.db.update(
        session,
        [for (final item in existing) item.copyWith(shopId: shopId)],
        transaction: transaction,
      );
      for (final item in moved) {
        await _announce(
          session,
          listId,
          ItemChange(
            kind: ItemChangeKind.upserted,
            itemId: item.id!,
            item: item,
            actorId: userId,
          ),
          itemName: item.name,
        );
      }
      return moved.length;
    });
  }
}
