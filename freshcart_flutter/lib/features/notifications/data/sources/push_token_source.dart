import 'package:freshcart_client/freshcart_client.dart' as dto;

/// Gets this device's push token.
///
/// Separate from the repository, so Firebase is only used to get the token.
/// Everything else (registering, muting, unregistering) is normal server
/// calls, and can be tested without Firebase.
abstract interface class PushTokenSource {
  /// Whether this platform supports push.
  Future<bool> isSupported();

  /// This device's current token, or null if unavailable.
  Future<String?> token();

  /// Which platform this is, for the server's records.
  dto.DevicePlatform get platform;
}
