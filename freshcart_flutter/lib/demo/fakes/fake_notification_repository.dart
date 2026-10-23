import 'package:freshcart_domain/freshcart_domain.dart';

/// [NotificationRepository] for one demo phone. Push is never supported (it's the web),
/// but settings are kept in memory so toggles stay where the user put them.
class FakeNotificationRepository implements NotificationRepository {
  NotificationPreferences _preferences = const NotificationPreferences();
  final _mutedLists = <ListId>{};

  @override
  Future<bool> isSupported() async => false;

  @override
  Future<Result<void>> registerDevice() async => const Ok(null);

  @override
  Future<Result<void>> unregisterDevice() async => const Ok(null);

  @override
  Future<Result<void>> setListMuted(
    ListId listId, {
    required bool muted,
  }) async {
    muted ? _mutedLists.add(listId) : _mutedLists.remove(listId);
    return const Ok(null);
  }

  @override
  Future<Result<bool>> isListMuted(ListId listId) async =>
      Ok(_mutedLists.contains(listId));

  @override
  Future<Result<NotificationPreferences>> notificationPreferences() async =>
      Ok(_preferences);

  @override
  Future<Result<NotificationPreferences>> setItemAddedNotificationsEnabled(
    bool value,
  ) async => _set(_preferences.copyWith(itemAdded: value));

  @override
  Future<Result<NotificationPreferences>> setMemberJoinedNotificationsEnabled(
    bool value,
  ) async => _set(_preferences.copyWith(memberJoined: value));

  @override
  Future<Result<NotificationPreferences>> setListFinishedNotificationsEnabled(
    bool value,
  ) async => _set(_preferences.copyWith(listFinished: value));

  Result<NotificationPreferences> _set(NotificationPreferences preferences) {
    _preferences = preferences;
    return Ok(preferences);
  }
}
