import 'package:freshcart_client/freshcart_client.dart' as dto;

/// Supplies this device's push registration token.
///
/// Split out from the repository so that the *only* thing Firebase is
/// responsible for is producing a token string. Everything else — registering
/// it, muting a list, unregistering on sign-out — is ordinary server traffic
/// that needs no Firebase at all, and is tested without it.
abstract interface class PushTokenSource {
  /// Whether this platform can produce a token.
  Future<bool> isSupported();

  /// This device's current token, or null if unavailable.
  Future<String?> token();

  /// Which platform this is, for the server's records.
  dto.DevicePlatform get platform;
}

/// The [PushTokenSource] used until Firebase is configured.
///
/// Reports unsupported, so the app degrades to live in-app updates only rather
/// than promising a notification setting the platform will not honour.
///
/// Replacing this with a `firebase_messaging` implementation is the whole of
/// the remaining work: request permission, read `getToken()`, and return it.
/// Nothing else in the app changes, which is the point of the port
/// (`docs/decisions.md` #7).
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
