import 'dart:convert';
import 'dart:io';

import 'package:freshcart_server/src/notifications/business/push_sender.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

/// Sends push notifications with Firebase (FCM HTTP v1 API), logged in as
/// a service account.
///
/// There's no official Firebase Admin SDK for Dart, so this calls the REST
/// API directly: one POST per phone to `projects/{projectId}/messages:send`.
/// The [http.Client] from `googleapis_auth` refreshes its own access token,
/// so it's created once and reused.
class FcmPushSender implements PushSender {
  const FcmPushSender._(this._client, this._projectId);

  final http.Client _client;
  final String _projectId;

  static const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  /// Creates a sender from the key file at [keyPath], or `null` if the file
  /// doesn't exist.
  ///
  /// Returns null (doesn't throw), because most developers won't have the
  /// key file. The server should still start, and use [LoggingPushSender]
  /// instead (decisions.md #7).
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
    // One request per phone: the v1 API can't send to many at once. And one
    // failing phone must not stop the others.
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
              // One notification per list in the tray: a newer one for the
              // same list replaces the older (decision #108), on Android by
              // tag and on iOS by collapse id.
              'android': {
                'notification': {'tag': message.listId.toString()},
              },
              'apns': {
                'headers': {'apns-collapse-id': message.listId.toString()},
              },
            },
          }),
        );
        if (response.statusCode != 200) {
          // An old token (app uninstalled, notifications off) is normal. Just
          // log it. (Old tokens aren't cleaned up yet.)
          session.log(
            '[fcm] delivery failed (${response.statusCode}): ${response.body}',
            level: LogLevel.warning,
          );
        }
      } on Object catch (error) {
        // Must never throw: a failed push must not make the save fail.
        session.log('[fcm] delivery error: $error', level: LogLevel.warning);
      }
    }
  }
}
