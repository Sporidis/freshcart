import 'package:freshcart_server/src/common/business/session_user.dart';
import 'package:freshcart_server/src/generated/protocol.dart';
import 'package:freshcart_server/src/notifications/business/device_token_service.dart';
import 'package:freshcart_server/src/notifications/business/list_mute_service.dart';
import 'package:freshcart_server/src/notifications/business/notification_preferences_service.dart';
import 'package:serverpod/serverpod.dart';

/// Endpoint for registering phones for push, and notification settings.
class NotificationEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Registers this phone to get push notifications for the caller.
  ///
  /// Safe to call again: an existing token is moved to the caller (no
  /// duplicate). So if someone else logs in on the phone, the previous
  /// user stops getting notifications there.
  Future<DeviceToken> registerDevice(
    Session session,
    String token,
    DevicePlatform platform,
  ) => DeviceTokenService.register(
    session,
    session.requireUserId,
    token,
    platform,
  );

  /// Stops push notifications to this phone. Called on sign-out.
  Future<void> unregisterDevice(Session session, String token) =>
      DeviceTokenService.unregister(session, token);

  /// Mutes or unmutes a list for the caller.
  Future<void> setListMuted(
    Session session,
    UuidValue listId,
    bool muted,
  ) => ListMuteService.setMuted(
    session,
    listId,
    session.requireUserId,
    muted: muted,
  );

  /// Whether the caller has muted [listId].
  Future<bool> isListMuted(Session session, UuidValue listId) =>
      ListMuteService.isMuted(session, listId, session.requireUserId);

  /// The caller's notification preferences (decisions.md #80).
  Future<NotificationPreferences> preferences(Session session) =>
      NotificationPreferencesService.forUser(session, session.requireUserId);

  /// Sets whether the caller is notified when someone adds an item.
  Future<NotificationPreferences> setItemAddedEnabled(
    Session session,
    bool value,
  ) => NotificationPreferencesService.setItemAdded(
    session,
    session.requireUserId,
    value,
  );

  /// Sets whether the caller is notified when someone joins a list.
  Future<NotificationPreferences> setMemberJoinedEnabled(
    Session session,
    bool value,
  ) => NotificationPreferencesService.setMemberJoined(
    session,
    session.requireUserId,
    value,
  );

  /// Sets whether the caller is notified when a list is finished.
  Future<NotificationPreferences> setListFinishedEnabled(
    Session session,
    bool value,
  ) => NotificationPreferencesService.setListFinished(
    session,
    session.requireUserId,
    value,
  );
}
