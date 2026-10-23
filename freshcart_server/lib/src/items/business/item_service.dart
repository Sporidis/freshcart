// The domain import has a prefix (`domain.`), because Serverpod's
// generated model is also called ShoppingItem. We only need the domain one
// for `sortOrderGap` and `sameProduct`, so server and app use the same
// numbers and rules.
import 'package:freshcart_domain/freshcart_domain.dart' as domain;
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/lists/business/list_service.dart';
import 'package:freshcart_server/src/notifications/business/notification_service.dart';
import 'package:freshcart_server/src/users/business/profile_service.dart';
import 'package:serverpod/serverpod.dart';

/// The logic for items on a list.
abstract final class ItemService {
  /// The channel name for item updates on one list.
  ///
  /// One channel per list, so someone watching one list doesn't get
  /// messages about all other lists.
  static String channelFor(UuidValue listId) => 'list-items-$listId';

  /// Sends a change to everyone watching [listId] (the live stream, for
  /// people with the app open).
  ///
  /// With [notifyAddedName], also queues a push for people with the app
  /// closed: only when an item was *added*. Ticking, unticking, editing,
  /// moving and deleting stay live-only; a push for those read as "X added
  /// Milk" (every change used to be queued, and the summary called them all
  /// additions) and woke phones for things nobody needs to hear about away
  /// from the list.
  static Future<void> _announce(
    Session session,
    UuidValue listId,
    ItemChange change, {
    String? notifyAddedName,
  }) async {
    await session.messages.postMessage(channelFor(listId), change);
    if (notifyAddedName == null) return;
    await NotificationService.enqueueAddition(
      session,
      listId: listId,
      actorId: change.actorId,
      actorName: await ProfileService.displayNameFor(session, change.actorId),
      itemName: notifyAddedName,
    );
  }

  /// All items on [listId], in the user's order (then by creation date for
  /// old items that all have the same sortOrder). The caller must be a
  /// member.
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

  /// The sortOrder for a new item: after the last item on [listId].
  ///
  /// Reads the last item first, instead of `MAX(sortOrder)` in SQL, because
  /// Serverpod's query builder can't do that without raw SQL. One extra
  /// read when adding is fine.
  static Future<double> _appendSortOrder(
    Session session,
    UuidValue listId, {
    Transaction? transaction,
  }) async {
    final last = await ShoppingItem.db.findFirstRow(
      session,
      where: (t) => t.listId.equals(listId),
      orderBy: (t) => t.sortOrder,
      orderDescending: true,
      transaction: transaction,
    );
    return (last?.sortOrder ?? 0) + domain.ShoppingItem.sortOrderGap;
  }

  /// Adds an item to [listId]. If the same product is already on the list
  /// and not checked (same name, shop and note, see
  /// `domain.ShoppingItem.sameProduct`), it adds to that item's quantity
  /// instead.
  ///
  /// Adding the same thing again means "I need more", not "add a second
  /// row". A checked item doesn't count: then a new row is made.
  ///
  /// All in one transaction, so two adds at the same moment can't both
  /// make a new row.
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
    await _requireShopOnList(session, listId, shopId);
    final now = DateTime.now().toUtc();

    final result = await session.db.transaction((transaction) async {
      // A list only has a few open items, so we compare them in Dart (with
      // the domain rule). Simpler than doing it in SQL, especially for the
      // note, which is stored as JSON.
      final open = await ShoppingItem.db.find(
        session,
        where: (t) => t.listId.equals(listId) & t.isChecked.equals(false),
        transaction: transaction,
      );
      ShoppingItem? existing;
      for (final row in open) {
        if (row.shopId == shopId &&
            domain.ShoppingItem.sameProduct(
              nameA: row.name,
              noteTextA: row.note?.text,
              nameB: name,
              noteTextB: noteText,
            )) {
          existing = row;
          break;
        }
      }

      if (existing != null) {
        return ShoppingItem.db.updateRow(
          session,
          existing.copyWith(
            quantity: existing.quantity + quantity,
            updatedAt: now,
          ),
          transaction: transaction,
        );
      }

      return ShoppingItem.db.insertRow(
        session,
        ShoppingItem(
          listId: listId,
          name: name,
          quantity: quantity,
          isChecked: false,
          sortOrder: await _appendSortOrder(
            session,
            listId,
            transaction: transaction,
          ),
          shopId: shopId,
          note: noteText == null
              ? null
              : Note(text: noteText, authorId: userId, updatedAt: now),
          addedBy: userId,
          createdAt: now,
          updatedAt: now,
        ),
        transaction: transaction,
      );
    });

    await _announce(
      session,
      listId,
      ItemChange(
        kind: ItemChangeKind.upserted,
        itemId: result.id!,
        item: result,
        actorId: userId,
      ),
      notifyAddedName: result.name,
    );
    // Save the name for suggestions. If this fails, the add must still
    // succeed.
    try {
      await _recordNameHistory(session, listId, name);
    } on Object catch (_) {
      // Ignored on purpose: the item was already added.
    }
    return result;
  }

  /// Remembers that [name] was added to [listId], for suggestions later.
  ///
  /// Updates the existing row if the name is already there (there's a
  /// unique index on listId + name), otherwise inserts one.
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

  /// Item names used on [listId] before that match [query], newest first.
  /// For the suggestion chips.
  ///
  /// Empty for less than 2 letters: one letter would match almost
  /// everything.
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

  /// Every item name ever used on [listId], newest first. For "Recently
  /// bought". Like [suggestNames], but without a search text.
  static Future<List<ItemNameHistory>> recentNames(
    Session session,
    UuidValue listId,
    UuidValue userId, {
    int limit = 40,
  }) async {
    await ListService.requireMembership(session, listId, userId);
    return ItemNameHistory.db.find(
      session,
      where: (t) => t.listId.equals(listId),
      orderBy: (t) => t.lastUsedAt,
      orderDescending: true,
      limit: limit,
    );
  }

  /// Saves [incoming], unless someone else changed the item first.
  ///
  /// The app sends the `updatedAt` it last saw. If the saved item is newer,
  /// we throw [EditConflictException] instead of overwriting the other
  /// person's change. On a shared list, two people editing at once is
  /// normal.
  static Future<ShoppingItem> save(
    Session session,
    ShoppingItem incoming,
    UuidValue userId,
  ) async {
    final result = await session.db.transaction((transaction) async {
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
      if (incoming.shopId != stored.shopId) {
        await _requireShopOnList(
          session,
          stored.listId,
          incoming.shopId,
          transaction: transaction,
        );
      }

      // listId, addedBy and createdAt are set by the server only. The app
      // can't move an item to another list or change who added it.
      //
      // Same for who checked it: the app only says IF it's checked. The
      // server fills in WHO and WHEN from the session. Otherwise someone
      // could fake "checked off by" someone else.
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
      return (saved: saved, becameChecked: becameChecked);
    });

    await _announce(
      session,
      result.saved.listId,
      ItemChange(
        kind: ItemChangeKind.upserted,
        itemId: result.saved.id!,
        item: result.saved,
        actorId: userId,
      ),
    );
    // The "list finished" notification must never make the save fail.
    if (result.becameChecked) {
      try {
        await NotificationService.maybeNotifyListFinished(
          session,
          result.saved.listId,
          actorId: userId,
        );
      } on Object catch (_) {
        // Ignored on purpose: the item was already saved.
      }
    }
    return result.saved;
  }

  /// Deletes an item (the caller must be on its list).
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
    );
  }

  /// Deletes all checked items on [listId]. Returns how many.
  ///
  /// One transaction (not [remove] in a loop): either all are deleted, or
  /// none. Never half.
  static Future<int> clearChecked(
    Session session,
    UuidValue listId,
    UuidValue userId,
  ) async {
    await ListService.requireMembership(session, listId, userId);
    final removed = await session.db.transaction(
      (transaction) => ShoppingItem.db.deleteWhere(
        session,
        where: (t) => t.listId.equals(listId) & t.isChecked.equals(true),
        transaction: transaction,
      ),
    );
    await _announceRemoved(session, listId, removed, actorId: userId);
    return removed.length;
  }

  /// Deletes the items in [itemIds] that are on [listId]. Returns how many.
  ///
  /// One transaction, like [clearChecked]: all or nothing. Only items on
  /// [listId] match, so an id from another list can never be deleted
  /// through this.
  static Future<int> removeMany(
    Session session,
    UuidValue listId,
    UuidValue userId,
    List<UuidValue> itemIds,
  ) async {
    await ListService.requireMembership(session, listId, userId);
    if (itemIds.isEmpty) return 0;
    final removed = await session.db.transaction(
      (transaction) => ShoppingItem.db.deleteWhere(
        session,
        where: (t) => t.listId.equals(listId) & t.id.inSet(itemIds.toSet()),
        transaction: transaction,
      ),
    );
    await _announceRemoved(session, listId, removed, actorId: userId);
    return removed.length;
  }

  /// Moves the items in [itemIds] (on [listId]) to [shopId] (null = no
  /// shop). Returns how many.
  ///
  /// One transaction, like [removeMany]: all or nothing, so items never end
  /// up split over two shops.
  static Future<int> moveMany(
    Session session,
    UuidValue listId,
    UuidValue userId,
    List<UuidValue> itemIds,
    UuidValue? shopId,
  ) async {
    await ListService.requireMembership(session, listId, userId);
    await _requireShopOnList(session, listId, shopId);
    if (itemIds.isEmpty) return 0;
    final now = DateTime.now().toUtc();
    final moved = await session.db.transaction((transaction) async {
      final existing = await ShoppingItem.db.find(
        session,
        where: (t) => t.listId.equals(listId) & t.id.inSet(itemIds.toSet()),
        transaction: transaction,
      );
      // A new updatedAt, so an edit based on the pre-move copy conflicts
      // instead of silently moving the item back.
      return ShoppingItem.db.update(
        session,
        [
          for (final item in existing)
            item.copyWith(shopId: shopId, updatedAt: now),
        ],
        transaction: transaction,
      );
    });
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
      );
    }
    return moved.length;
  }

  /// Throws [ShopNotFoundException] unless [shopId] is null or a shop on
  /// [listId]: an item can't be tagged with another list's shop.
  static Future<void> _requireShopOnList(
    Session session,
    UuidValue listId,
    UuidValue? shopId, {
    Transaction? transaction,
  }) async {
    if (shopId == null) return;
    final shop = await Shop.db.findById(
      session,
      shopId,
      transaction: transaction,
    );
    if (shop == null || shop.listId != listId) throw ShopNotFoundException();
  }

  /// Tells everyone watching [listId] that [removed] are gone. Called after
  /// the transaction commits, so nobody hears about a delete that rolled
  /// back.
  static Future<void> _announceRemoved(
    Session session,
    UuidValue listId,
    List<ShoppingItem> removed, {
    required UuidValue actorId,
  }) async {
    for (final item in removed) {
      await _announce(
        session,
        listId,
        ItemChange(
          kind: ItemChangeKind.removed,
          itemId: item.id!,
          actorId: actorId,
        ),
      );
    }
  }
}
