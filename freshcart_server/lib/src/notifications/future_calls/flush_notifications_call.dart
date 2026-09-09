import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/notifications/business/notification_service.dart';
import 'package:serverpod/serverpod.dart';

/// Flushes one list's buffered notifications after the aggregation window.
class FlushNotificationsCall extends FutureCall<ListReference> {
  @override
  Future<void> invoke(Session session, ListReference? object) async {
    if (object == null) return;
    await NotificationService.flush(session, object.listId);
  }
}
