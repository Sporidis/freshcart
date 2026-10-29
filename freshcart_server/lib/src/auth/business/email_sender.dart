import 'package:freshcart_server/src/auth/business/email_message.dart';
import 'package:serverpod/serverpod.dart';

/// Sends emails (verification and password-reset codes).
///
/// An interface (not an email provider directly), like `PushSender`: the
/// login logic can be tested without sending real email, and the provider
/// can be replaced by changing one class.
abstract interface class EmailSender {
  /// Sends [message]. Throws if it couldn't be sent: the code is the whole
  /// point of the request, so Serverpod must roll the request back.
  Future<void> send(Session session, EmailMessage message);
}

/// An [EmailSender] for development: logs the email instead of sending it.
///
/// The log is how you read the code when testing sign-up locally. That's
/// only safe because `server.dart` refuses to start outside development
/// with this sender.
class LoggingEmailSender implements EmailSender {
  /// Creates the logging sender.
  const LoggingEmailSender();

  @override
  Future<void> send(Session session, EmailMessage message) async {
    session.log(
      '[LoggingEmailSender] not sent, logged instead\n'
      '  to:      ${message.to}\n'
      '  subject: ${message.subject}\n'
      '  ${message.body}',
    );
  }
}
