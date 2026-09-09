import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/notifications/business/notification_digest.dart';
import 'package:freshcart_server/src/notifications/business/push_sender.dart';
import 'package:serverpod/serverpod.dart';

/// Decides who gets notified about what, and when.
abstract final class NotificationService {
  /// How long changes are buffered before being summarised into one push.
  ///
  /// Long enough that adding several items in a row is one notification, short
  /// enough that a collaborator is not left waiting.
  static const Duration aggregationWindow = Duration(seconds: 20);

  /// The name the flush future call is registered under.
  static const String flushCallName = 'flushListNotifications';

  /// The sender used for delivery. Swapped for a fake in tests.
  static PushSender sender = const LoggingPushSender();

  /// Buffers a change and makes sure a flush is scheduled.
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

    // Keyed on the list, so a second change inside the window joins the
    // existing batch instead of scheduling a competing flush.
    //
    // `futureCallWithDelay` is marked deprecated in 3.4.13 in favour of
    // "generated future call methods", but running `serverpod generate` against
    // a project-defined FutureCall produces no such dispatcher in this version —
    // the replacement is not shipped yet. This is the only working API, so the
    // deprecation is suppressed deliberately rather than worked around.
    // Revisit when the generated dispatcher appears.
    // ignore: deprecated_member_use
    await session.serverpod.futureCallWithDelay(
      flushCallName,
      ListReference(listId: listId),
      aggregationWindow,
      identifier: 'flush-$listId',
    );
  }

  /// The device tokens that should receive news about [listId].
  ///
  /// Excludes the actor — nobody wants a phone buzzing about their own edit —
  /// and anyone who has muted the list.
  static Future<List<DeviceToken>> recipientTokens(
    Session session,
    UuidValue listId,
    Set<UuidValue> actorIds,
  ) async {
    final members = await ListMember.db.find(
      session,
      where: (t) => t.listId.equals(listId),
    );
    final muted = await ListMute.db.find(
      session,
      where: (t) => t.listId.equals(listId),
    );
    final mutedIds = muted.map((m) => m.userId).toSet();

    final recipients = <UuidValue>{
      for (final member in members)
        if (!actorIds.contains(member.userId) &&
            !mutedIds.contains(member.userId))
          member.userId,
    };
    if (recipients.isEmpty) return [];

    return DeviceToken.db.find(
      session,
      where: (t) => t.ownerId.inSet(recipients),
    );
  }

  /// Summarises and sends everything buffered for [listId], then clears it.
  static Future<void> flush(Session session, UuidValue listId) async {
    final pending = await PendingItemNotification.db.find(
      session,
      where: (t) => t.listId.equals(listId),
    );
    if (pending.isEmpty) return;

    // Cleared first: a delivery failure must not leave a batch that replays
    // the same notification on the next flush.
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
    );
    if (tokens.isEmpty) return;

    await sender.send(
      session,
      PushMessage(
        tokens: tokens.map((t) => t.token).toList(),
        title: digest.title,
        body: digest.body,
        listId: listId,
      ),
    );
  }
}
