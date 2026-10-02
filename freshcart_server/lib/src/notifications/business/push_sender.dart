import 'package:serverpod/serverpod.dart';

/// A push notification, ready to send.
class PushMessage {
  /// Creates a message for [tokens].
  const PushMessage({
    required this.tokens,
    required this.title,
    required this.body,
    required this.listId,
  });

  /// The phones (FCM tokens) to send to.
  final List<String> tokens;

  /// Notification title.
  final String title;

  /// Notification body.
  final String body;

  /// The list it's about, so tapping it can open that list.
  final UuidValue listId;
}

/// Sends push notifications.
///
/// An interface (not Firebase directly), so the logic (who, what, when)
/// can be tested without Firebase, and FCM could be replaced by changing
/// one class (decisions.md #7).
abstract interface class PushSender {
  /// Sends [message]. Must never throw: a failed push must not make the
  /// save fail.
  Future<void> send(Session session, PushMessage message);
}

/// A [PushSender] for development: logs the notification instead of
/// sending it.
///
/// Used when there's no Firebase key. Logging (instead of doing nothing)
/// lets you see the notification logic work without Firebase.
class LoggingPushSender implements PushSender {
  /// Creates the logging sender.
  const LoggingPushSender();

  @override
  Future<void> send(Session session, PushMessage message) async {
    session.log(
      '[push] "${message.title}" / "${message.body}" '
      '-> ${message.tokens.length} device(s) for list ${message.listId}',
    );
  }
}
