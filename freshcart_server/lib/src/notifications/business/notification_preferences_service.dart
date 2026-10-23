import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Which kinds of push notifications a user wants (decisions.md #80).
/// Different from [ListMute], which mutes one whole list.
abstract final class NotificationPreferencesService {
  /// [userId]'s preferences, or the defaults if they never changed them.
  /// Reading doesn't create a database row.
  static Future<NotificationPreferences> forUser(
    Session session,
    UuidValue userId,
  ) async {
    final existing = await NotificationPreferences.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );
    return existing ?? NotificationPreferences(userId: userId);
  }

  /// [forUser] for each of [userIds], in one query.
  static Future<Map<UuidValue, NotificationPreferences>> forUsers(
    Session session,
    Set<UuidValue> userIds,
  ) async {
    final saved = await NotificationPreferences.db.find(
      session,
      where: (t) => t.userId.inSet(userIds),
    );
    final byUser = {for (final p in saved) p.userId: p};
    return {
      for (final id in userIds)
        id: byUser[id] ?? NotificationPreferences(userId: id),
    };
  }

  static Future<NotificationPreferences> setItemAdded(
    Session session,
    UuidValue userId,
    bool value,
  ) => _upsert(session, userId, (p) => p.copyWith(itemAdded: value));

  static Future<NotificationPreferences> setMemberJoined(
    Session session,
    UuidValue userId,
    bool value,
  ) => _upsert(session, userId, (p) => p.copyWith(memberJoined: value));

  static Future<NotificationPreferences> setListFinished(
    Session session,
    UuidValue userId,
    bool value,
  ) => _upsert(session, userId, (p) => p.copyWith(listFinished: value));

  static Future<NotificationPreferences> _upsert(
    Session session,
    UuidValue userId,
    NotificationPreferences Function(NotificationPreferences) update,
  ) async {
    final existing = await NotificationPreferences.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );
    if (existing == null) {
      return NotificationPreferences.db.insertRow(
        session,
        update(NotificationPreferences(userId: userId)),
      );
    }
    return NotificationPreferences.db.updateRow(session, update(existing));
  }
}
