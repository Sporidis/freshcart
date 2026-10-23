import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/lists/business/list_access.dart';
import 'package:serverpod/serverpod.dart';

/// The item names used on a list before, for suggestions while typing and
/// for "Recently bought".
abstract final class ItemNameHistoryService {
  /// Remembers that [name] was added to [listId], for suggestions later.
  ///
  /// Updates the existing row if the name is already there (there's a
  /// unique index on listId + name), otherwise inserts one.
  static Future<void> record(
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
    await ListAccess.requireMember(session, listId, userId);
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
    await ListAccess.requireMember(session, listId, userId);
    return ItemNameHistory.db.find(
      session,
      where: (t) => t.listId.equals(listId),
      orderBy: (t) => t.lastUsedAt,
      orderDescending: true,
      limit: limit,
    );
  }
}
