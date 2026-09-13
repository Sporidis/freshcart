import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// A user's own choices about which push notifications they receive
/// (decisions #80, phase 2) -- see [NotificationPreferences]'s own doc
/// comment for how this differs from [ListMute].
abstract final class NotificationPreferencesService {
  /// [userId]'s preferences, or the defaults if they have never changed
  /// anything. No row is inserted just to answer a read.
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
