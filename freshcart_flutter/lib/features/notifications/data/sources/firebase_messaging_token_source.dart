import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_flutter/features/notifications/data/sources/push_token_source.dart';

/// The real [PushTokenSource], using Firebase Cloud Messaging.
///
/// Only for Android and iOS, never web (decisions.md #8).
///
/// There's no handler for incoming messages: the phone shows the
/// notification by itself, and the app doesn't need to do anything with
/// it (decisions.md #37, #38).
class FirebaseMessagingTokenSource implements PushTokenSource {
  /// Creates the source for [platform] (`android` or `ios`).
  const FirebaseMessagingTokenSource(this.platform);

  @override
  final dto.DevicePlatform platform;

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<String?> token() async {
    // Ask for permission first. getToken() would ask too, but then saying
    // "no" throws an error. This way "no" just gives null.
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return null;
    }
    return FirebaseMessaging.instance.getToken();
  }
}
