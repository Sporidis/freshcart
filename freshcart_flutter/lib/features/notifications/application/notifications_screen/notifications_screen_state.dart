import 'package:freshcart_domain/freshcart_domain.dart';

/// Everything `NotificationsScreen` renders, already derived.
class NotificationsScreenState {
  const NotificationsScreenState({
    required this.preferences,
    required this.lists,
  });

  /// The user's push choices; null while they load, so the toggles never
  /// show a default as if it were the user's real setting.
  final NotificationPreferences? preferences;

  /// The lists that get a per-list mute row; empty until they load.
  final List<ShoppingList> lists;
}
