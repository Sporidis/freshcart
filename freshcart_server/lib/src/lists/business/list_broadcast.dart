import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/lists/business/member_profiles.dart';
import 'package:serverpod/serverpod.dart';

/// Sends lists to the phones watching them.
abstract final class ListBroadcast {
  /// The channel name for updates to one list.
  ///
  /// One channel per list, so someone watching one list doesn't get
  /// messages about all other lists.
  static String channelFor(UuidValue listId) => 'list-$listId';

  /// Sends the list (with members) to everyone watching it.
  ///
  /// Sends the whole list (not just what changed, like for items), because
  /// a list is one small row. It runs after the save, so a failure here is
  /// logged, not thrown: the change went through, and other phones catch up
  /// when they next load or reconnect.
  static Future<void> send(Session session, UuidValue listId) async {
    try {
      final list = await ShoppingList.db.findById(session, listId);
      if (list == null) return;
      final withProfiles = await MemberProfiles.attachTo(session, list);
      await session.messages.postMessage(channelFor(listId), withProfiles);
    } on Object catch (error, stackTrace) {
      session.log(
        'Broadcasting list $listId failed',
        level: LogLevel.warning,
        exception: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Sends every list [userId] is on again, after they changed their name,
  /// colour or photo. So others see the change right away.
  ///
  /// Like [send], a failure is logged, not thrown: the profile is
  /// already saved.
  static Future<void> resendListsOf(
    Session session,
    UuidValue userId,
  ) async {
    final memberships = await ListMember.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );
    for (final m in memberships) {
      await send(session, m.listId);
    }
  }
}
