/// An email, ready to send.
class EmailMessage {
  /// Creates a message to [to].
  const EmailMessage({
    required this.to,
    required this.subject,
    required this.body,
  });

  /// The address to send to.
  final String to;

  /// The subject line.
  final String subject;

  /// The plain-text body.
  final String body;
}
