import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'items_ui_controller.g.dart';

/// The items section's own UI state for one list: which mode it is in, and
/// the little facts about *this list right now* that must survive a rebuild.
///
/// Its own provider rather than fields on `ItemsSectionController`: that view
/// model's `build()` re-runs whenever anything it watches changes (a live
/// item update, a shop edit), which would silently reset a flag stored on it
/// -- mid-drag, mid-selection, mid-typing. Provider state, not widget state,
/// for the same reason (decisions #47): a rotation or a route pop-and-push
/// must not forget a selection or pop a dismissed celebration back up.
@riverpod
class ItemsUiController extends _$ItemsUiController {
  @override
  ItemsUiState build(ListId listId) => const ItemsUiState();

  // ── Selection ──────────────────────────────────────────────────────────
  // There is no "selection mode is active" flag: the mode *is* a non-empty
  // selection. One source of truth, so the header, the checkbox slide and
  // the contextual bar can never disagree about whether it is on.

  /// Adds or removes [id] from the selection.
  void toggleSelection(ItemId id) {
    final selection = state.selection;
    state = state.copyWith(
      selection: selection.contains(id)
          ? ({...selection}..remove(id))
          : {...selection, id},
    );
  }

  /// Leaves selection mode without acting on it.
  void clearSelection() => state = state.copyWith(selection: const {});

  // ── Search ─────────────────────────────────────────────────────────────
  // Open and query are separate on purpose: tapping the search icon opens an
  // empty field that has to stay open, not collapse the instant it renders
  // with nothing in it.

  void openSearch() => state = state.copyWith(searchActive: true);

  /// Filtering is local and per-keystroke (§16: "no spinner"), so there is
  /// nothing to await here.
  void updateQuery(String query) =>
      state = state.copyWith(searchActive: true, searchQuery: query);

  /// Closes search and forgets the query.
  void closeSearch() =>
      state = state.copyWith(searchActive: false, searchQuery: '');

  // ── Rearrange ──────────────────────────────────────────────────────────

  void startRearrange() => state = state.copyWith(rearranging: true);

  void stopRearrange() => state = state.copyWith(rearranging: false);

  // ── Done section & celebration ─────────────────────────────────────────

  /// Folds the Done section away, or opens it again. Per list: the big
  /// weekly list wants the trolley visible, a short one reads better folded.
  void toggleDoneCollapsed() =>
      state = state.copyWith(doneCollapsed: !state.doneCollapsed);

  /// "Keep list": hide the celebration without touching any items.
  void dismissCelebration() =>
      state = state.copyWith(celebrationDismissed: true);

  /// Called once the list is no longer fully checked, so a "Keep list" does
  /// not carry over to the next time it is.
  void resetCelebration() {
    if (state.celebrationDismissed) {
      state = state.copyWith(celebrationDismissed: false);
    }
  }
}

/// See [ItemsUiController]. Raw facts only -- ranking them into one
/// `ItemsMode` is `ItemsSectionController`'s job.
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
