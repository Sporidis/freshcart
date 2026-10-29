import 'dart:convert';

import 'package:freshcart_server/src/auth/business/email_message.dart';
import 'package:freshcart_server/src/auth/business/email_sender.dart';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

/// Sends email with Brevo's transactional email API.
///
/// Brevo is an EU company, so email addresses and codes stay in the EU
/// (security-plan 1.3b). One POST per email to `/v3/smtp/email`; the API key
/// comes from `passwords.yaml` (`brevoApiKey`), never from the code.
class BrevoEmailSender implements EmailSender {
  /// Creates a sender that sends from [senderEmail] with [apiKey].
  ///
  /// [senderEmail] must be a sender verified in Brevo (Senders, domains,
  /// IPs), or Brevo refuses the email.
  BrevoEmailSender({
    required String apiKey,
    required String senderEmail,
    http.Client? client,
  }) : _apiKey = apiKey,
       _senderEmail = senderEmail,
       _client = client ?? http.Client();

  final String _apiKey;
  final String _senderEmail;
  final http.Client _client;

  static final Uri _endpoint = Uri.parse('https://api.brevo.com/v3/smtp/email');

  /// The name people see as the sender.
  static const String _senderName = 'FreshCart';

  /// How long to wait for Brevo. Serverpod sends the code inside the
  /// transaction that creates the sign-up request, so a hanging call would
  /// hold a database connection; better to fail, roll back and let the user
  /// retry.
  static const Duration _timeout = Duration(seconds: 10);

  @override
  Future<void> send(Session session, EmailMessage message) async {
    final response = await _client
        .post(
          _endpoint,
          headers: {
            'api-key': _apiKey,
            'content-type': 'application/json',
            'accept': 'application/json',
          },
          body: jsonEncode({
            'sender': {'name': _senderName, 'email': _senderEmail},
            'to': [
              {'email': message.to},
            ],
            'subject': message.subject,
            // Brevo requires htmlContent without a template. The body is
            // plain text, so it's escaped to stay plain text.
            'htmlContent': const HtmlEscape().convert(message.body),
          }),
        )
        .timeout(_timeout);

    if (response.statusCode != 201) {
      // Only the status and Brevo's error code: its `message` can repeat
      // the address, and this ends up in the logs.
      throw StateError(
        'Brevo refused the email '
        '(${response.statusCode}, ${_errorCode(response.body)})',
      );
    }
  }

  /// Brevo's error `code` (like `invalid_parameter`) from an error [body],
  /// or `unknown` if the body isn't Brevo's JSON (a proxy's error page).
  static String _errorCode(String body) {
    try {
      return switch (jsonDecode(body)) {
        {'code': final String code} => code,
        _ => 'unknown',
      };
    } on FormatException {
      return 'unknown';
    }
  }
}
