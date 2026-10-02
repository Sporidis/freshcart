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

/// A placeholder [PushTokenSource] that always says "push not supported".
///
/// Used on web (see `main.dart`). The app then only uses live updates
/// inside the app, and doesn't show push settings that wouldn't work.
///
/// Phones use `FirebaseMessagingTokenSource` instead. The rest of the app
/// doesn't care which one is used (decisions.md #7).
class UnconfiguredPushTokenSource implements PushTokenSource {
  /// Creates the placeholder source.
  const UnconfiguredPushTokenSource(this.platform);

  @override
  final dto.DevicePlatform platform;

  @override
  Future<bool> isSupported() async => false;

  @override
  Future<String?> token() async => null;
}
