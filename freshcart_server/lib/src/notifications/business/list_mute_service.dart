import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/lists/business/list_access.dart';
import 'package:serverpod/serverpod.dart';

/// Which lists a user has muted (no push notifications from them).
abstract final class ListMuteService {
  /// Mutes or unmutes [listId] for [userId], who must be a member.
  static Future<void> setMuted(
    Session session,
    UuidValue listId,
    UuidValue userId, {
    required bool muted,
  }) async {
    await ListAccess.requireMember(session, listId, userId);

    if (!muted) {
      await ListMute.db.deleteWhere(
        session,
        where: (t) => t.listId.equals(listId) & t.userId.equals(userId),
      );
      return;
    }
    final existing = await ListMute.db.findFirstRow(
      session,
      where: (t) => t.listId.equals(listId) & t.userId.equals(userId),
    );
    if (existing == null) {
      await ListMute.db.insertRow(
        session,
        ListMute(listId: listId, userId: userId),
      );
    }
  }

  /// Whether [userId] has muted [listId].
  static Future<bool> isMuted(
    Session session,
    UuidValue listId,
    UuidValue userId,
  ) async {
    final existing = await ListMute.db.findFirstRow(
      session,
      where: (t) => t.listId.equals(listId) & t.userId.equals(userId),
    );
    return existing != null;
  }
}
