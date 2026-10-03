import 'package:freshcart_domain/src/core/result.dart';
import 'package:freshcart_domain/src/lists/value_objects/list_id.dart';
import 'package:freshcart_domain/src/notifications/entities/notification_preferences.dart';

/// The interface for push notifications (when the app is closed). Doesn't
/// mention Firebase.
///
/// Firebase (FCM) is only used in the implementation of this interface,
/// nowhere else (decisions.md #7). Live updates inside the app are
/// something else (Serverpod streams, the repositories' `watch` methods).
///
/// ## Known limitation
///
/// On an iPhone in the EU, the web app (PWA) can't get push notifications.
/// Live updates inside the app still work. Real iOS push needs the native
/// app and a paid Apple Developer account. So a failed registration there
/// is expected, not a bug.
abstract interface class PushPort {
  /// Whether push can work on this device. False on web (including EU
  /// iPhone PWAs). Used to hide settings that wouldn't work.
  Future<bool> isSupported();

  /// Registers this device to receive pushes for the signed-in user.
  Future<Result<void>> registerDevice();

  /// Stops pushes to this device. Called on sign-out.
  Future<Result<void>> unregisterDevice();

  /// Mutes or unmutes notifications for a single list.
  Future<Result<void>> setListMuted(ListId listId, {required bool muted});

  /// Whether the user muted list [listId]. The "read" side of
  /// [setListMuted] (decisions.md #80).
  Future<Result<bool>> isListMuted(ListId listId);

  /// Which kinds of push notifications the user wants (for all lists).
  Future<Result<NotificationPreferences>> notificationPreferences();

  /// Sets whether the signed-in user is notified when someone adds an item.
  Future<Result<NotificationPreferences>> setItemAddedNotificationsEnabled(
    bool value,
  );

  /// Sets whether the signed-in user is notified when someone joins a list.
  Future<Result<NotificationPreferences>> setMemberJoinedNotificationsEnabled(
    bool value,
  );

  /// Sets whether the signed-in user is notified when a list is finished.
  Future<Result<NotificationPreferences>> setListFinishedNotificationsEnabled(
    bool value,
  );
}
