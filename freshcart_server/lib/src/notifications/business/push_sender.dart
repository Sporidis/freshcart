import 'package:serverpod/serverpod.dart';

/// A push message ready to be delivered.
class PushMessage {
  /// Creates a message for [tokens].
  const PushMessage({
    required this.tokens,
    required this.title,
    required this.body,
    required this.listId,
  });

  /// The FCM registration tokens to deliver to.
  final List<String> tokens;

  /// Notification title.
  final String title;

  /// Notification body.
  final String body;

  /// The list the notification concerns, so tapping it can deep-link.
  final UuidValue listId;
}

/// Delivers push messages.
///
/// An interface, not a Firebase call, so the *decision* logic — who to notify,
/// what to say, when — is testable without a network or a Firebase project, and
/// so swapping FCM for something else later touches one class
/// (`docs/decisions.md` #7).
abstract interface class PushSender {
  /// Delivers [message]. Implementations must not throw: a failed push must
  /// never fail the write that triggered it.
  Future<void> send(Session session, PushMessage message);
}

/// The development [PushSender]: logs instead of delivering.
///
/// Used until a Firebase project and service-account credentials are
/// configured. Logging rather than silently discarding means the aggregation
/// and recipient logic can be watched working end to end without FCM.
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
