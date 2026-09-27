import 'dart:async';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/items/application/celebration_controller.dart';
import 'package:freshcart_flutter/features/items/application/done_section_controller.dart';
import 'package:freshcart_flutter/features/items/application/item_search_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_screen_state.dart';
import 'package:freshcart_flutter/features/items/application/rearrange_controller.dart';
import 'package:freshcart_flutter/features/items/application/selection_controller.dart';
import 'package:freshcart_flutter/features/lists/application/list_membership_provider.dart';
import 'package:freshcart_flutter/features/shops/application/shops_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'items_screen_controller.g.dart';

/// The view model behind the list detail screen's items: composes the per-list
/// controllers into one derived [ItemsScreenState], and owns the multi-step
/// actions ("delete, then leave selection mode only if that worked").
///
/// It does *not* replace those controllers -- each still owns its one piece
/// of state -- and it never touches `BuildContext`: sheets, snackbars and
/// text fields stay in the widget. Actions hand back a [Failure] (or null)
/// and the screen decides how to show it.
///
/// Keyed by the whole [ShoppingList] rather than its id because that's what
/// the screen is handed, and the header needs its name and members; a
/// changed list (freezed equality) simply gets a fresh instance, which is
/// safe because every piece of mode state lives in its own provider.
@riverpod
class ItemsScreenController extends _$ItemsScreenController {
  ListId get _listId => list.id;

  ItemsController get _items =>
      ref.read(itemsControllerProvider(_listId).notifier);

  @override
  ItemsScreenState build(ShoppingList list) {
    final listId = list.id;
    final itemsOutcome = ref.watch(itemsControllerProvider(listId));
    final allItems = itemsOutcome.dataOrNull ?? const <ShoppingItem>[];
    final shops =
        ref.watch(shopsControllerProvider(listId)).dataOrNull ?? const <Shop>[];
    final shopFilter = ref.watch(shopFilterControllerProvider(listId));
    final selection = ref.watch(selectionControllerProvider(listId));
    final search = ref.watch(itemSearchControllerProvider(listId));
    final rearranging = ref.watch(rearrangeControllerProvider(listId));

    // Forgets a "Keep list" dismissal the moment the list stops being fully
    // checked, so the celebration shows again the next time it applies.
    // Lives here, not in the widget, because it's a rule about the data, not
    // about what's on screen -- and a listen in `build()` is re-registered
    // (not stacked) on every rebuild.
    ref.listen(itemsControllerProvider(listId), (_, next) {
      final nextItems = next.dataOrNull;
      if (nextItems != null && !_allDone(nextItems)) {
        ref.read(celebrationControllerProvider(listId).notifier).reset();
      }
    });

    // "Clear checked after shopping" (decisions #79): the instant the list
    // *becomes* fully checked while someone is looking at it, clear it
    // silently. Not on the initial load (no previous snapshot) -- a list
    // that was already all-done when opened must not wipe itself on arrival.
    // The preference is checked inside the callback so the listen is
    // registered unconditionally, as `ref.listen` in build must be.
    ref.listen(itemsControllerProvider(listId), (previous, next) {
      if (!list.clearCheckedAfterShopping) return;
      final before = previous?.dataOrNull;
      final after = next.dataOrNull;
      if (before == null || after == null) return;
      if (!_allDone(before) && _allDone(after)) {
        unawaited(_items.clearChecked());
      }
    });

    final visible = [
      for (final item in allItems)
        if (item.matchesShopFilter(shopFilter)) item,
    ];

    return ItemsScreenState(
      list: list,
      mode: _modeFor(
        rearranging: rearranging,
        selecting: selection.isNotEmpty,
        searching: search.active,
      ),
      allItems: allItems,
      openItems: [
        for (final i in visible)
          if (!i.isChecked) i,
      ],
      doneItems: [
        for (final i in visible)
          if (i.isChecked) i,
      ],
      shops: shops,
      shopFilter: shopFilter,
      me: ref.watch(myMembershipProvider(list)),
      selection: selection,
      searchQuery: search.query,
      doneCollapsed: ref.watch(doneSectionControllerProvider(listId)),
      // Mutually exclusive with the auto-clear above: two ways of handling
      // the same moment, not layered on top of each other.
      showCelebration:
          !list.clearCheckedAfterShopping &&
          _allDone(allItems) &&
          !ref.watch(celebrationControllerProvider(listId)),
      isLoading: itemsOutcome.isLoading && allItems.isEmpty,
      loadFailure: itemsOutcome.loadFailure,
    );
  }

  static bool _allDone(List<ShoppingItem> items) =>
      items.isNotEmpty && items.every((i) => i.isChecked);

  /// Ranks the three mode flags into the one [ItemsMode] the screen draws.
  static ItemsMode _modeFor({
    required bool rearranging,
    required bool selecting,
    required bool searching,
  }) {
    switch ((rearranging, selecting, searching)) {
      case (true, _, _):
        return ItemsMode.rearrange;
      case (false, true, _):
        return ItemsMode.select;
      case (false, false, true):
        return ItemsMode.search;
      case (false, false, false):
        return ItemsMode.browse;
    }
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

  void toggleDoneCollapsed() =>
      ref.read(doneSectionControllerProvider(_listId).notifier).toggle();

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

  /// Enters rearrange mode, or does nothing on the "All" tab (see
  /// [ItemsScreenState.canRearrange]).
  void startRearrange() {
    if (state.canRearrange) {
      ref.read(rearrangeControllerProvider(_listId).notifier).enter();
    }
  }

  void stopRearrange() =>
      ref.read(rearrangeControllerProvider(_listId).notifier).exit();

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

  void toggleSelection(ItemId id) =>
      ref.read(selectionControllerProvider(_listId).notifier).toggle(id);

  void clearSelection() =>
      ref.read(selectionControllerProvider(_listId).notifier).clear();

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

  void openSearch() =>
      ref.read(itemSearchControllerProvider(_listId).notifier).open();

  void closeSearch() =>
      ref.read(itemSearchControllerProvider(_listId).notifier).close();

  void updateQuery(String query) => ref
      .read(itemSearchControllerProvider(_listId).notifier)
      .updateQuery(query);
}
