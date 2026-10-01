import 'package:freshcart_domain/freshcart_domain.dart';

/// Everything `ListSettingsScreen` renders, already derived.
///
/// Pure Dart on purpose, same as `ItemsSectionState`: domain types only, so
/// it stays unit-testable without a widget tree. The name field's draft,
/// saving flag and error are *not* here -- they belong to the text field in
/// the widget, and this state is rebuilt whenever the list changes (which,
/// on a shared list, can be someone else's edit arriving mid-typing).
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

  /// Every list the user is on, for the switcher at the top.
  final List<ShoppingList> allLists;

  /// This list's shops, active or not -- each row is its on/off switch.
  final List<Shop> shops;

  /// Decides delete-for-everyone versus leave. False until the signed-in
  /// identity resolves -- the safe default (see `isListOwner`).
  final bool isOwner;

  /// The list hasn't arrived yet -- distinct from a failed load.
  final bool isLoading;

  /// The list failed to load at all: the screen tier, replacing the form.
  final Failure? loadFailure;
}
