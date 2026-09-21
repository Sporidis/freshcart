import 'package:freshcart_domain/freshcart_domain.dart';

/// An in-memory [PushPort] for application/widget tests.
class FakePushRepository implements PushPort {
  /// What [isSupported] returns.
  bool supported = true;

  /// What [isListMuted] returns per list, defaulting to unmuted for any
  /// list not explicitly configured.
  final Map<ListId, bool> mutedByList = {};

  /// What [setListMuted] returns.
  Result<void> setListMutedResult = const Ok<void>(null);

  /// Every (listId, muted) pair [setListMuted] was called with, in order.
  final List<({ListId listId, bool muted})> setListMutedCalls = [];

  /// How many times [registerDevice] was called.
  int registerDeviceCallCount = 0;

  /// How many times [unregisterDevice] was called.
  int unregisterDeviceCallCount = 0;

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<Result<void>> registerDevice() async {
    registerDeviceCallCount++;
    return const Ok(null);
  }

  @override
  Future<Result<void>> unregisterDevice() async {
    unregisterDeviceCallCount++;
    return const Ok(null);
  }

  @override
  Future<Result<void>> setListMuted(
    ListId listId, {
    required bool muted,
  }) async {
    setListMutedCalls.add((listId: listId, muted: muted));
    if (setListMutedResult.isOk) mutedByList[listId] = muted;
    return setListMutedResult;
  }

  @override
  Future<Result<bool>> isListMuted(ListId listId) async =>
      Ok(mutedByList[listId] ?? false);

  /// The current in-memory preferences, updated in place by the setters
  /// below so a test can read what the last write actually produced.
  NotificationPreferences preferences = const NotificationPreferences();

  @override
  Future<Result<NotificationPreferences>> notificationPreferences() async =>
      Ok(preferences);

  @override
  Future<Result<NotificationPreferences>> setItemAddedNotificationsEnabled(
    bool value,
  ) async {
    preferences = preferences.copyWith(itemAdded: value);
    return Ok(preferences);
  }

  @override
  Future<Result<NotificationPreferences>> setMemberJoinedNotificationsEnabled(
    bool value,
  ) async {
    preferences = preferences.copyWith(memberJoined: value);
    return Ok(preferences);
  }

  @override
  Future<Result<NotificationPreferences>> setListFinishedNotificationsEnabled(
    bool value,
  ) async {
    preferences = preferences.copyWith(listFinished: value);
    return Ok(preferences);
  }
}
