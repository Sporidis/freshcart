import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/notifications/business/notification_digest.dart';
import 'package:freshcart_server/src/notifications/business/notification_preferences_service.dart';
import 'package:freshcart_server/src/notifications/business/push_sender.dart';
import 'package:serverpod/serverpod.dart';

/// Decides who gets which push notification, and when.
abstract final class NotificationService {
  /// How long changes are collected before sending one push.
  ///
  /// Long enough that adding several items is one notification, short
  /// enough that others don't wait long.
  static const Duration aggregationWindow = Duration(seconds: 20);

  /// The name of the scheduled "send collected changes" job.
  static const String flushCallName = 'flushListNotifications';

  /// What actually sends the push. Tests use a fake.
  static PushSender sender = const LoggingPushSender();

  /// Saves a change, and makes sure sending is scheduled.
  static Future<void> enqueue(
    Session session, {
    required UuidValue listId,
    required UuidValue actorId,
    required String actorName,
    required String itemName,
    required ItemChangeKind kind,
  }) async {
    await PendingItemNotification.db.insertRow(
      session,
      PendingItemNotification(
        listId: listId,
        actorId: actorId,
        actorName: actorName,
        itemName: itemName,
        kind: kind,
      ),
    );

    // One scheduled job per list, so a second change in the same window
    // joins the same batch.
    //
    // `futureCallWithDelay` is deprecated in Serverpod 3.4.13, but the
    // replacement isn't available yet in this version. So we use it anyway
    // and hide the warning. Change this when the replacement exists.
    // ignore: deprecated_member_use
    await session.serverpod.futureCallWithDelay(
      flushCallName,
      ListReference(listId: listId),
      aggregationWindow,
      identifier: 'flush-$listId',
    );
  }

  /// The phones that should get a notification about [listId].
  ///
  /// Leaves out:
  /// - the person who made the change (no buzz for your own edit);
  /// - people who muted this list;
  /// - people who turned off this kind of notification ([isEnabled]).
  ///
  /// If [isEnabled] isn't given, everyone else gets it (decisions.md #80).
  static Future<List<DeviceToken>> recipientTokens(
    Session session,
    UuidValue listId,
    Set<UuidValue> actorIds, {
    bool Function(NotificationPreferences) isEnabled = _alwaysNotified,
  }) async {
    final members = await ListMember.db.find(
      session,
      where: (t) => t.listId.equals(listId),
    );
    final muted = await ListMute.db.find(
      session,
      where: (t) => t.listId.equals(listId),
    );
    final mutedIds = muted.map((m) => m.userId).toSet();

    final candidates = <UuidValue>[
      for (final member in members)
        if (!actorIds.contains(member.userId) &&
            !mutedIds.contains(member.userId))
          member.userId,
    ];
    if (candidates.isEmpty) return [];

    final preferences = await Future.wait(
      candidates.map(
        (id) => NotificationPreferencesService.forUser(session, id),
      ),
    );
    final recipients = <UuidValue>{
      for (var i = 0; i < candidates.length; i++)
        if (isEnabled(preferences[i])) candidates[i],
    };
    if (recipients.isEmpty) return [];

    return DeviceToken.db.find(
      session,
      where: (t) => t.ownerId.inSet(recipients),
    );
  }

  static bool _alwaysNotified(NotificationPreferences _) => true;

  /// Sends one notification for everything collected for [listId], then
  /// clears it.
  static Future<void> flush(Session session, UuidValue listId) async {
    final pending = await PendingItemNotification.db.find(
      session,
      where: (t) => t.listId.equals(listId),
    );
    if (pending.isEmpty) return;

    // Clear first. If sending fails, the same notification must not be sent
    // again next time.
    await PendingItemNotification.db.deleteWhere(
      session,
      where: (t) => t.listId.equals(listId),
    );

    final list = await ShoppingList.db.findById(session, listId);
    if (list == null) return;

    final digest = NotificationDigest.summarise(list.name, pending);
    if (digest == null) return;

    final tokens = await recipientTokens(
      session,
      listId,
      pending.map((p) => p.actorId).toSet(),
      isEnabled: (p) => p.itemAdded,
    );
    await _deliver(session, listId, digest, tokens);
  }

  /// Sends "Someone joins a list" right away when [newMemberId] joins (not
  /// when an existing member taps the invite again; `ListService.join`
  /// checks that). Not collected like item changes, because a join is
  /// always one event (decisions.md #80).
  static Future<void> notifyMemberJoined(
    Session session,
    UuidValue listId, {
    required UuidValue newMemberId,
    required String newMemberName,
    required String listName,
  }) async {
    final copy = NotificationDigest.memberJoined(listName, newMemberName);
    final tokens = await recipientTokens(
      session,
      listId,
      {newMemberId},
      isEnabled: (p) => p.memberJoined,
    );
    await _deliver(session, listId, copy, tokens);
  }

  /// Sends "A list is finished" once, when the last item gets checked.
  ///
  /// Only called when an item just BECAME checked (`ItemService.save`
  /// decides). So editing an already-checked item doesn't send it again
  /// (decisions.md #80).
  static Future<void> maybeNotifyListFinished(
    Session session,
    UuidValue listId, {
    required UuidValue actorId,
  }) async {
    final stillOpen = await ShoppingItem.db.count(
      session,
      where: (t) => t.listId.equals(listId) & t.isChecked.equals(false),
    );
    if (stillOpen > 0) return;

    final total = await ShoppingItem.db.count(
      session,
      where: (t) => t.listId.equals(listId),
    );
    // An empty list isn't "finished".
    if (total == 0) return;

    final list = await ShoppingList.db.findById(session, listId);
    if (list == null) return;

    final copy = NotificationDigest.listFinished(list.name, total);
    final tokens = await recipientTokens(
      session,
      listId,
      {actorId},
      isEnabled: (p) => p.listFinished,
    );
    await _deliver(session, listId, copy, tokens);
  }

  static Future<void> _deliver(
    Session session,
    UuidValue listId,
    ({String title, String body}) copy,
    List<DeviceToken> tokens,
  ) async {
    if (tokens.isEmpty) return;
    await sender.send(
      session,
      PushMessage(
        tokens: tokens.map((t) => t.token).toList(),
        title: copy.title,
        body: copy.body,
        listId: listId,
      ),
    );
  }
}
