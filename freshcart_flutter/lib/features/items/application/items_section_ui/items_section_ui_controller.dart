import 'dart:async';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/items/application/items_section_ui/items_section_ui_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'items_section_ui_controller.g.dart';

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
class ItemsSectionUiController extends _$ItemsSectionUiController {
  /// Fires [settleNow] once the ticks have stopped for a moment.
  Timer? _settleTimer;

  @override
  ItemsSectionUiState build(ListId listId) {
    ref.onDispose(() => _settleTimer?.cancel());
    return const ItemsSectionUiState();
  }

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

  // ── Batch check-off ─────────────────────────────────────────────────────
  // Design v3: a tick fills the circle (and saves) at once, but the row stays
  // where it is until the ticks stop for a moment. Then everything ticked in
  // that burst moves to Done together, with one toast. Ticking down a list
  // in the shop no longer makes the rows jump under your thumb.

  /// [id] was just checked: hold it in place, and restart the wait.
  void startSettling(ItemId id, Duration wait) {
    // A Set literal keeps insertion order, so this is also the tap order.
    state = state.copyWith(settling: {...state.settling, id});
    _settleTimer?.cancel();
    _settleTimer = Timer(wait, settleNow);
  }

  /// [id] was unchecked again before it settled: it just stays open.
  void stopSettling(ItemId id) {
    if (!state.settling.contains(id)) return;
    final rest = {...state.settling}..remove(id);
    state = state.copyWith(settling: rest);
    if (rest.isEmpty) _settleTimer?.cancel();
  }

  /// Releases the held rows to Done now. [ItemsSectionUiState.settleCount] goes up,
  /// which is what the screen listens to for the toast.
  void settleNow() {
    _settleTimer?.cancel();
    _settleTimer = null;
    if (state.settling.isEmpty) return;
    state = state.copyWith(
      settling: const {},
      lastSettled: state.settling.toList(),
      settleCount: state.settleCount + 1,
    );
  }

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
