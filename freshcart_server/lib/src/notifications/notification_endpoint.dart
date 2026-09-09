import 'package:freshcart_server/src/common/business/session_user.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/lists/business/list_service.dart';
import 'package:serverpod/serverpod.dart';

/// Device registration and per-list notification settings.
class NotificationEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Registers this device to receive pushes for the caller.
  ///
  /// Idempotent: re-registering an existing token re-points it at the caller
  /// rather than inserting a duplicate, so a shared device that changes hands
  /// does not keep notifying the previous user.
  Future<DeviceToken> registerDevice(
    Session session,
    String token,
    DevicePlatform platform,
  ) async {
    final userId = session.requireUserId;
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

  /// Stops pushes to this device. Called on sign-out.
  Future<void> unregisterDevice(Session session, String token) async {
    await DeviceToken.db.deleteWhere(
      session,
      where: (t) => t.token.equals(token),
    );
  }

  /// Mutes or unmutes a list for the caller.
  Future<void> setListMuted(
    Session session,
    UuidValue listId,
    bool muted,
  ) async {
    final userId = session.requireUserId;
    await ListService.requireMembership(session, listId, userId);

    if (!muted) {
      await ListMute.db.deleteWhere(
        session,
        where: (t) => t.listId.equals(listId) & t.userId.equals(userId),
      );
      return;
    }
    final existing = await ListMute.db.findFirstRow(
      session,
      where: (t) => t.listId.equals(listId) & t.userId.equals(userId),
    );
    if (existing == null) {
      await ListMute.db.insertRow(
        session,
        ListMute(listId: listId, userId: userId),
      );
    }
  }

  /// Whether the caller has muted [listId].
  Future<bool> isListMuted(Session session, UuidValue listId) async {
    final existing = await ListMute.db.findFirstRow(
      session,
      where: (t) =>
          t.listId.equals(listId) & t.userId.equals(session.requireUserId),
    );
    return existing != null;
  }
}
