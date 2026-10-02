import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'items_ui_controller.g.dart';

/// UI state for the items area of one list: the mode (select, search,
/// rearrange) and small things like "is Done folded".
///
/// Why its own provider, and not fields in `ItemsSectionController`? That
/// controller's `build()` runs again on every item update, which would
/// reset these values in the middle of selecting or typing.
///
/// Why a provider and not widget state? So rotating the phone or going back
/// and forth doesn't lose the selection (decisions.md #47).
@riverpod
class ItemsUiController extends _$ItemsUiController {
  @override
  ItemsUiState build(ListId listId) => const ItemsUiState();

  // ── Selection ──────────────────────────────────────────────────────────
  // There's no "select mode on" flag. Select mode is on when something is
  // selected. One value, so nothing can disagree about it.

  /// Selects [id], or unselects it if it was selected.
  void toggleSelection(ItemId id) {
    final selection = state.selection;
    state = state.copyWith(
      selection: selection.contains(id)
          ? ({...selection}..remove(id))
          : {...selection, id},
    );
  }

  /// Leaves select mode without doing anything.
  void clearSelection() => state = state.copyWith(selection: const {});

  // ── Search ─────────────────────────────────────────────────────────────
  // "Search open" and "search text" are separate. Otherwise an empty search
  // field would close itself right after opening.

  void openSearch() => state = state.copyWith(searchActive: true);

  /// Updates the search text. Searching happens on the phone (no server),
  /// so it's instant.
  void updateQuery(String query) =>
      state = state.copyWith(searchActive: true, searchQuery: query);

  /// Closes search and clears the text.
  void closeSearch() =>
      state = state.copyWith(searchActive: false, searchQuery: '');

  // ── Rearrange ──────────────────────────────────────────────────────────

  void startRearrange() => state = state.copyWith(rearranging: true);

  void stopRearrange() => state = state.copyWith(rearranging: false);

  // ── Done section & celebration ─────────────────────────────────────────

  /// Folds or unfolds the "Done" section. Remembered per list.
  void toggleDoneCollapsed() =>
      state = state.copyWith(doneCollapsed: !state.doneCollapsed);

  /// "Keep list": hides the "all done" card. Items stay as they are.
  void dismissCelebration() =>
      state = state.copyWith(celebrationDismissed: true);

  /// Called when the list isn't complete anymore. Forgets "Keep list", so
  /// the card shows again next time everything is checked.
  void resetCelebration() {
    if (state.celebrationDismissed) {
      state = state.copyWith(celebrationDismissed: false);
    }
  }
}

/// The state of [ItemsUiController]. Just the raw values.
/// `ItemsSectionController` turns them into one `ItemsMode`.
class ItemsUiState {
  const ItemsUiState({
    this.selection = const {},
    this.searchActive = false,
    this.searchQuery = '',
    this.rearranging = false,
    this.doneCollapsed = false,
    this.celebrationDismissed = false,
  });

  final Set<ItemId> selection;
  final bool searchActive;
  final String searchQuery;
  final bool rearranging;
  final bool doneCollapsed;
  final bool celebrationDismissed;

  ItemsUiState copyWith({
    Set<ItemId>? selection,
    bool? searchActive,
    String? searchQuery,
    bool? rearranging,
    bool? doneCollapsed,
    bool? celebrationDismissed,
  }) => ItemsUiState(
    selection: selection ?? this.selection,
    searchActive: searchActive ?? this.searchActive,
    searchQuery: searchQuery ?? this.searchQuery,
    rearranging: rearranging ?? this.rearranging,
    doneCollapsed: doneCollapsed ?? this.doneCollapsed,
    celebrationDismissed: celebrationDismissed ?? this.celebrationDismissed,
  );
}
