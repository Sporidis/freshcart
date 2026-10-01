import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/lists/application/lists/lists_controller.dart';
import 'package:freshcart_flutter/features/notifications/application/notification_preferences/notification_preferences_controller.dart';
import 'package:freshcart_flutter/features/notifications/application/notifications_screen/notifications_screen_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifications_screen_controller.g.dart';

/// The view model behind `NotificationsScreen`: the push preferences and the
/// lists to mute, side by side.
///
/// Earns its place by combining two sources. Each per-list mute row keeps
/// its own `ListMuteController` -- one row, one notifier.
@riverpod
class NotificationsScreenController extends _$NotificationsScreenController {
  NotificationPreferencesController get _preferences =>
      ref.read(notificationPreferencesControllerProvider.notifier);

  @override
  NotificationsScreenState build() => NotificationsScreenState(
    preferences: ref.watch(notificationPreferencesControllerProvider).value,
    lists: ref.watch(listsControllerProvider).dataOrNull ?? const [],
  );

  Future<Failure?> setItemAdded(bool value) => _preferences.setItemAdded(value);

  Future<Failure?> setMemberJoined(bool value) =>
      _preferences.setMemberJoined(value);

  Future<Failure?> setListFinished(bool value) =>
      _preferences.setListFinished(value);
}
