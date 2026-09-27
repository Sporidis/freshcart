import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_flutter/features/notifications/data/sources/push_token_source.dart';

/// The real [PushTokenSource], backed by Firebase Cloud Messaging.
///
/// Android and iOS only — never constructed for web (see
/// `docs/decisions.md` #8). No background message handler is registered:
/// this app's push is purely closed-app delivery of a server-summarised
/// notification (decisions #37, #38), so there is nothing for the app to
/// do with a message once it arrives. The OS displays it from the payload
/// alone.
class FirebaseMessagingTokenSource implements PushTokenSource {
  /// Creates the source for [platform] (`android` or `ios`).
  const FirebaseMessagingTokenSource(this.platform);

  @override
  final dto.DevicePlatform platform;

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<String?> token() async {
    // getToken() would ask for permission itself, but asking explicitly first
    // means a denial is a clean null rather than an exception, and matches
    // this port's contract: "no token is not a failure".
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return null;
    }
    return FirebaseMessaging.instance.getToken();
  }
}
