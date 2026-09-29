import 'dart:async';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/items/application/items/items_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_screen/items_screen_state.dart';
import 'package:freshcart_flutter/features/items/application/items_ui/items_ui_controller.dart';
import 'package:freshcart_flutter/features/lists/application/list/list_providers.dart';
import 'package:freshcart_flutter/features/shops/application/shop_filter/shop_filter_controller.dart';
import 'package:freshcart_flutter/features/shops/application/shops/shops_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'items_screen_controller.g.dart';

/// The view model behind the list detail screen's items: composes the
/// list's items, shops, filter and [ItemsUiController] into one derived
/// [ItemsScreenState], and owns the multi-step actions ("delete, then leave
/// selection mode only if that worked").
///
/// The items widgets talk to this notifier and nothing else, which is why it
/// also carries one-line forwards: one door per screen beats making every
/// widget know which of four providers owns which action. It never touches
/// `BuildContext` -- sheets, snackbars and text fields stay in the widget.
/// Actions hand back a [Failure] (or null) and the screen decides how to
/// show it.
///
/// Keyed by the whole [ShoppingList] rather than its id because that's what
/// the screen is handed, and the header needs its name and members; a
/// changed list (freezed equality) simply gets a fresh instance, which is
/// safe because all mode state lives in [ItemsUiController].
@riverpod
class ItemsScreenController extends _$ItemsScreenController {
  ListId get _listId => list.id;

  ItemsController get _items =>
      ref.read(itemsControllerProvider(_listId).notifier);

  ItemsUiController get _ui =>
      ref.read(itemsUiControllerProvider(_listId).notifier);

  @override
  ItemsScreenState build(ShoppingList list) {
    final listId = list.id;
    final itemsOutcome = ref.watch(itemsControllerProvider(listId));
    final allItems = itemsOutcome.dataOrNull ?? const <ShoppingItem>[];
    final shops =
        ref.watch(shopsControllerProvider(listId)).dataOrNull ?? const <Shop>[];
    final shopFilter = ref.watch(shopFilterControllerProvider(listId));
    final ui = ref.watch(itemsUiControllerProvider(listId));

    ref.listen(itemsControllerProvider(listId), (previous, next) {
      final before = previous?.dataOrNull;
      final after = next.dataOrNull;
      if (after == null) return;

      // Forgets a "Keep list" dismissal the moment the list stops being
      // fully checked, so the celebration shows again the next time.
      if (!_allDone(after)) _ui.resetCelebration();

      // "Clear checked after shopping" (decisions #79): the instant the list
      // *becomes* fully checked while someone is looking at it, clear it
      // silently. Not on the initial load (no previous snapshot) -- a list
      // that was already all-done when opened must not wipe itself on
      // arrival.
      if (list.clearCheckedAfterShopping &&
          before != null &&
          !_allDone(before) &&
          _allDone(after)) {
        unawaited(_items.clearChecked());
      }
    });

    return ItemsScreenState(
      list: list,
      mode: _modeFor(ui),
      allItems: allItems,
      shops: shops,
      shopFilter: shopFilter,
      me: ref.watch(myMembershipProvider(list)),
      selection: ui.selection,
      searchQuery: ui.searchQuery,
      doneCollapsed: ui.doneCollapsed,
      // Mutually exclusive with the auto-clear above: two ways of handling
      // the same moment, not layered on top of each other.
      showCelebration:
          !list.clearCheckedAfterShopping &&
          _allDone(allItems) &&
          !ui.celebrationDismissed,
      isLoading: itemsOutcome.isLoading && allItems.isEmpty,
      loadFailure: itemsOutcome.loadFailure,
    );
  }

  static bool _allDone(List<ShoppingItem> items) =>
      items.isNotEmpty && items.every((i) => i.isChecked);

  /// Ranks the mode flags into the one [ItemsMode] the screen draws.
  static ItemsMode _modeFor(ItemsUiState ui) {
    if (ui.rearranging) return ItemsMode.rearrange;
    if (ui.selection.isNotEmpty) return ItemsMode.select;
    if (ui.searchActive) return ItemsMode.search;
    return ItemsMode.browse;
  }

  // ── Rows ────────────────────────────────────────────────────────────────

  Future<Failure?> toggle(ShoppingItem item) => _items.toggle(item);

  Future<Failure?> setQuantity(ShoppingItem item, int quantity) => _items.edit(
    item,
    name: item.name,
    quantity: quantity,
    shopId: item.shopId,
    noteText: item.note?.text,
  );

  Future<Failure?> edit(
    ShoppingItem item, {
    required String name,
    required int quantity,
    ShopId? shopId,
    String? noteText,
  }) => _items.edit(
    item,
    name: name,
    quantity: quantity,
    shopId: shopId,
    noteText: noteText,
  );

  Future<Failure?> remove(ShoppingItem item) => _items.remove(item);

  /// Hides the row now and returns its undo; the write lands later.
  void Function() swipeDelete(ShoppingItem item) => _items.swipeDelete(item);

  Future<Failure?> clearChecked() => _items.clearChecked();

  void toggleDoneCollapsed() => _ui.toggleDoneCollapsed();

  /// "Keep list" on the completion celebration.
  void dismissCelebration() => _ui.dismissCelebration();

  // ── Adding ──────────────────────────────────────────────────────────────

  /// The add bar's one-tap path: tagged to whichever shop tab is showing.
  Future<Failure?> quickAdd(String name) =>
      _items.add(name: name, shopId: state.shopFilter);

  Future<Failure?> add({
    required String name,
    required int quantity,
    ShopId? shopId,
    String? noteText,
  }) => _items.add(
    name: name,
    quantity: quantity,
    shopId: shopId,
    noteText: noteText,
  );

  // ── Rearrange ───────────────────────────────────────────────────────────

  /// Enters rearrange mode, if [ItemsScreenState.canRearrange] allows it.
  void startRearrange() {
    if (state.canRearrange) _ui.startRearrange();
  }

  void stopRearrange() => _ui.stopRearrange();

  /// Moves the open row at [oldIndex] to [newIndex].
  ///
  /// `onReorderItem`'s newIndex is already adjusted for the dragged row's
  /// own removal, so it names the insertion slot in the list *without* that
  /// row directly -- no "subtract one if moving down" bookkeeping.
  Future<Failure?> reorderOpen(int oldIndex, int newIndex) {
    final open = state.openItems;
    final item = open[oldIndex];
    final remaining = [...open]..removeAt(oldIndex);
    return _items.reorder(
      item,
      before: newIndex > 0 ? remaining[newIndex - 1] : null,
      after: newIndex < remaining.length ? remaining[newIndex] : null,
    );
  }

  // ── Selection ───────────────────────────────────────────────────────────

  void toggleSelection(ItemId id) => _ui.toggleSelection(id);

  void clearSelection() => _ui.clearSelection();

  /// Deletes the selection; leaves selection mode only on success, so a
  /// failed write never costs the user what they picked.
  Future<Failure?> deleteSelected() async {
    final failure = await _items.removeSelected(state.selection);
    if (failure == null) clearSelection();
    return failure;
  }

  /// Re-tags the selection to [shopId] (null = untagged); same
  /// clear-only-on-success rule as [deleteSelected].
  Future<Failure?> moveSelected(ShopId? shopId) async {
    final failure = await _items.moveSelected(state.selection, shopId);
    if (failure == null) clearSelection();
    return failure;
  }

  // ── Search ──────────────────────────────────────────────────────────────

  void openSearch() => _ui.openSearch();

  void closeSearch() => _ui.closeSearch();

  void updateQuery(String query) => _ui.updateQuery(query);

  /// Search's "add" paths: untagged, since search ignores the shop tab.
  Future<Failure?> addFromSearch(String name) => _items.add(name: name);
}
