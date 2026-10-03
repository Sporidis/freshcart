import 'package:freshcart_domain/freshcart_domain.dart';

/// The data `NotificationsScreen` shows.
class NotificationsScreenState {
  const NotificationsScreenState({
    required this.preferences,
    required this.lists,
    this.preferencesFailure,
  });

  /// The user's push settings, or null while loading (so no fake default
  /// switches are shown).
  final NotificationPreferences? preferences;

  /// Why [preferences] couldn't load. Null while loading or after it
  /// worked.
  final Failure? preferencesFailure;

  /// The lists to show a mute row for. Empty until loaded.
  final List<ShoppingList> lists;
}
