import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Which phones get a user's push notifications.
abstract final class DeviceTokenService {
  /// Registers [token] for [userId].
  ///
  /// Safe to call again: an existing token is moved to [userId] (no
  /// duplicate). So if someone else logs in on the phone, the previous
  /// user stops getting notifications there.
  static Future<DeviceToken> register(
    Session session,
    UuidValue userId,
    String token,
    DevicePlatform platform,
  ) async {
    final existing = await DeviceToken.db.findFirstRow(
      session,
      where: (t) => t.token.equals(token),
    );
    if (existing != null) {
      return DeviceToken.db.updateRow(
        session,
        existing.copyWith(ownerId: userId, platform: platform),
      );
    }
    return DeviceToken.db.insertRow(
      session,
      DeviceToken(ownerId: userId, token: token, platform: platform),
    );
  }

  /// Stops push notifications to the phone with [token].
  static Future<void> unregister(Session session, String token) async {
    await DeviceToken.db.deleteWhere(
      session,
      where: (t) => t.token.equals(token),
    );
  }
}
