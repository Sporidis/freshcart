import 'package:freshcart_domain/freshcart_domain.dart';

/// The data `ListSettingsScreen` shows. Plain Dart, so it can be tested
/// without widgets.
///
/// The name being typed, the "saving" flag and the error are NOT here.
/// This state is rebuilt every time the list changes, and on a shared list
/// that can be someone else's edit while you're typing. So the screen keeps
/// those itself.
class ListSettingsScreenState {
  const ListSettingsScreenState({
    required this.list,
    required this.allLists,
    required this.shops,
    required this.isOwner,
    this.isLoading = false,
    this.loadFailure,
  });

  /// The list being edited; null until it has loaded.
  final ShoppingList? list;

  /// All the user's lists, for the list switcher at the top.
  final List<ShoppingList> allLists;

  /// All this list's shops (shown or hidden). Each gets an on/off switch.
  final List<Shop> shops;

  /// Whether to show "Delete" (owner) or "Leave" (member). False until we
  /// know who the user is, to be safe (see `isListOwner`).
  final bool isOwner;

  /// Still loading (not the same as failed).
  final bool isLoading;

  /// Set when the list couldn't load. Then a full error screen is shown.
  final Failure? loadFailure;
}
