import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/notifications/business/notification_service.dart';
import 'package:serverpod/serverpod.dart';

/// The scheduled job that sends one list's collected changes as a push,
/// 20 seconds after the first change (`aggregationWindow`).
class FlushNotificationsCall extends FutureCall<ListReference> {
  @override
  Future<void> invoke(Session session, ListReference? object) async {
    if (object == null) return;
    await NotificationService.flush(session, object.listId);
  }
}
