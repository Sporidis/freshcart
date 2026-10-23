import 'package:freshcart_client/freshcart_client.dart' as dto;
import 'package:freshcart_flutter/features/notifications/data/sources/push_token_source.dart';

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
