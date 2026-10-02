import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/notifications/data/repositories/push_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_preferences_controller.g.dart';

/// Which push notifications the user wants. For the "Push" section on the
/// Notifications screen (decisions.md #80).
@riverpod
class NotificationPreferencesController
    extends _$NotificationPreferencesController {
  /// Loads the preferences. If that fails, it stays an [Err] (no default
  /// values). Default switches would look like the user's real settings,
  /// and flipping one could save the opposite of what they wanted.
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
