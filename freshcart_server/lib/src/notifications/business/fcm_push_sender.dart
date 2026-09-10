import 'dart:convert';
import 'dart:io';

import 'package:freshcart_server/src/notifications/business/push_sender.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

/// Delivers push through the FCM HTTP v1 API, authenticated as a service
/// account.
///
/// There is no official Firebase Admin SDK for Dart, so this speaks the REST
/// API directly: one signed-in [http.Client] from `googleapis_auth`, one POST
/// per token to `projects/{projectId}/messages:send`. `googleapis_auth`
/// refreshes the access token itself, so the client is created once and
/// reused for the life of the server.
class FcmPushSender implements PushSender {
  const FcmPushSender._(this._client, this._projectId);

  final http.Client _client;
  final String _projectId;

  static const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  /// Builds a sender from the service-account key at [keyPath], or returns
  /// `null` if that file does not exist.
  ///
  /// `null`, not a thrown exception: a missing key is the expected state for
  /// every developer who has not downloaded one (see
  /// `docs/decisions.md` #7), and the server must still start and fall back
  /// to [LoggingPushSender] rather than refuse to boot.
  static Future<FcmPushSender?> tryCreate(String keyPath) async {
    final file = File(keyPath);
    if (!file.existsSync()) return null;

    final raw = await file.readAsString();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final projectId = json['project_id'] as String;
    final credentials = auth.ServiceAccountCredentials.fromJson(json);
    final client = await auth.clientViaServiceAccount(credentials, _scopes);
    return FcmPushSender._(client, projectId);
  }

  @override
  Future<void> send(Session session, PushMessage message) async {
    // One request per token: the v1 API has no multicast endpoint (that was
    // a v0/legacy-API feature), and a failed token must not stop the rest
    // from being delivered.
    for (final token in message.tokens) {
      try {
        final response = await _client.post(
          Uri.parse(
            'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'message': {
              'token': token,
              'notification': {'title': message.title, 'body': message.body},
              'data': {'listId': message.listId.toString()},
            },
          }),
        );
        if (response.statusCode != 200) {
          // An unregistered/expired token is routine (uninstalled app, opted
          // out) and not worth more than a log line; there is no per-token
          // cleanup use case yet to react to it with.
          session.log(
            '[fcm] delivery failed (${response.statusCode}): ${response.body}',
            level: LogLevel.warning,
          );
        }
      } on Object catch (error) {
        // The interface's contract: must not throw. A push failure must
        // never fail the write that triggered it.
        session.log('[fcm] delivery error: $error', level: LogLevel.warning);
      }
    }
  }
}
