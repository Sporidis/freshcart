import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/notifications/data/repositories/push_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_preferences_controller.g.dart';

/// The signed-in user's own choices about which push notifications they
/// receive -- the Notifications screen's "Push" section (decisions #80,
/// phase 2).
@riverpod
class NotificationPreferencesController
    extends _$NotificationPreferencesController {
  /// A failed read stays an [Err] rather than falling back to defaults:
  /// defaults drawn as switches look exactly like the user's real choices,
  /// and flipping one would then set the opposite of what they meant.
  @override
  Future<Result<NotificationPreferences>> build() =>
      ref.watch(pushRepositoryProvider).notificationPreferences();

  /// Sets whether "Someone adds an item" notifies.
  Future<Failure?> setItemAdded(bool value) => _set(
    value,
    (v) => ref.read(pushRepositoryProvider).setItemAddedNotificationsEnabled(v),
  );

  /// Sets whether "Someone joins a list" notifies.
  Future<Failure?> setMemberJoined(bool value) => _set(
    value,
    (v) =>
        ref.read(pushRepositoryProvider).setMemberJoinedNotificationsEnabled(v),
  );

  /// Sets whether "A list is finished" notifies.
  Future<Failure?> setListFinished(bool value) => _set(
    value,
    (v) =>
        ref.read(pushRepositoryProvider).setListFinishedNotificationsEnabled(v),
  );

  Future<Failure?> _set(
    bool value,
    Future<Result<NotificationPreferences>> Function(bool) write,
  ) async {
    final result = await write(value);
    switch (result) {
      case Ok<NotificationPreferences>(:final value):
        if (ref.mounted) state = AsyncData(Ok(value));
        return null;
      case Err<NotificationPreferences>(:final failure):
        return failure;
    }
  }
}
