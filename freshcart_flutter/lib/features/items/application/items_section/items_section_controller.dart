import 'dart:async';

import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/items/application/items/items_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_state.dart';
import 'package:freshcart_flutter/features/items/application/items_ui/items_ui_controller.dart';
import 'package:freshcart_flutter/features/items/application/list_completion/list_completion_providers.dart';
import 'package:freshcart_flutter/features/lists/application/list/list_providers.dart';
import 'package:freshcart_flutter/features/shops/application/shop_filter/shop_filter_controller.dart';
import 'package:freshcart_flutter/features/shops/application/shops/shops_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'items_section_controller.g.dart';

/// The controller for the items on the list screen.
///
/// It combines the items, shops, shop filter and [ItemsUiController] into
/// one [ItemsSectionState]. It also runs actions with several steps (for
/// example "delete, then leave select mode, but only if it worked").
///
/// The item widgets only talk to this controller. That's why it also has
/// simple one-line methods that just pass a call on: widgets don't need to
/// know which of the four providers does what.
///
/// It never uses `BuildContext`. Sheets and snackbars stay in the widget.
/// Methods return a [Failure] (or null), and the screen decides how to show
/// it.
///
/// It takes the whole [ShoppingList] (not just its id), because the header
/// needs the name and members. If the list changes, a new controller is
/// made. That's fine, because the mode state lives in [ItemsUiController].
@riverpod
class ItemsSectionController extends _$ItemsSectionController {
  ListId get _listId => list.id;

  ItemsController get _items =>
      ref.read(itemsControllerProvider(_listId).notifier);

  ItemsUiController get _ui =>
      ref.read(itemsUiControllerProvider(_listId).notifier);

  @override
  ItemsSectionState build(ShoppingList list) {
    final listId = list.id;
    final itemsOutcome = ref.watch(itemsControllerProvider(listId));
    final allItems = itemsOutcome.dataOrNull ?? const <ShoppingItem>[];
    final shops =
        ref.watch(shopsControllerProvider(listId)).dataOrNull ?? const <Shop>[];
    final shopFilter = ref.watch(shopFilterControllerProvider(listId));
    final ui = ref.watch(itemsUiControllerProvider(listId));

    // What happens when the list becomes complete (or not) is in its own
    // provider. See [listCompletion] for why it can't be done here.
    ref.watch(listCompletionProvider(list));

    return ItemsSectionState(
      list: list,
      mode: _modeFor(ui),
      allItems: allItems,
      shops: shops,
      shopFilter: shopFilter,
      me: ref.watch(myMembershipProvider(list)),
      selection: ui.selection,
      searchQuery: ui.searchQuery,
      doneCollapsed: ui.doneCollapsed,
      // Either the celebration card or the auto-clear, never both.
      showCelebration:
          !list.clearCheckedAfterShopping &&
          allChecked(allItems) &&
          !ui.celebrationDismissed,
      isLoading: itemsOutcome.isLoading && allItems.isEmpty,
      loadFailure: itemsOutcome.loadFailure,
    );
  }

  /// Turns the mode flags into one [ItemsMode]. If several are on, this
  /// decides which wins.
  static ItemsMode _modeFor(ItemsUiState ui) {
    if (ui.rearranging) return ItemsMode.rearrange;
    if (ui.selection.isNotEmpty) return ItemsMode.select;
    if (ui.searchActive) return ItemsMode.search;
    return ItemsMode.browse;
  }

  /// Loads the items again. Used by the Retry button.
  void retryLoad() => ref.invalidate(itemsControllerProvider(_listId));

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

  /// Hides the row now and returns an undo function. The real delete
  /// happens a few seconds later.
  void Function() swipeDelete(ShoppingItem item) => _items.swipeDelete(item);

  Future<Failure?> clearChecked() => _items.clearChecked();

  void toggleDoneCollapsed() => _ui.toggleDoneCollapsed();

  /// The "Keep list" button on the "all done" card.
  void dismissCelebration() => _ui.dismissCelebration();

  // ── Adding ──────────────────────────────────────────────────────────────

  /// Quick add (type + Enter). Uses the shop of the selected tab.
  Future<Failure?> quickAdd(String name) =>
      _items.add(name: name, shopId: state.shopFilter);

  /// The "Make it x{n}" button on the "already on the list" card. Just
  /// calls [setQuantity], because it's the same change.
  Future<Failure?> bumpQuantity(ShoppingItem item) =>
      setQuantity(item, item.quantity + 1);

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

  /// Starts rearrange mode, if [ItemsSectionState.canRearrange] allows it.
  void startRearrange() {
    if (state.canRearrange) _ui.startRearrange();
  }

  void stopRearrange() => _ui.stopRearrange();

  /// Moves the open row at [oldIndex] to [newIndex].
  ///
  /// [newIndex] is already the position in the list WITHOUT the dragged
  /// row (Flutter's `onReorderItem` does that), so no "minus one when
  /// moving down" is needed.
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

  /// Deletes the selected items. Only leaves select mode if it worked, so
  /// on an error the user keeps their selection.
  Future<Failure?> deleteSelected() async {
    final failure = await _items.removeSelected(state.selection);
    if (failure == null) clearSelection();
    return failure;
  }

  /// Moves the selected items to [shopId] (null = no shop). Like
  /// [deleteSelected], only leaves select mode if it worked.
  Future<Failure?> moveSelected(ShopId? shopId) async {
    final failure = await _items.moveSelected(state.selection, shopId);
    if (failure == null) clearSelection();
    return failure;
  }

  // ── Search ──────────────────────────────────────────────────────────────

  void openSearch() => _ui.openSearch();

  void closeSearch() => _ui.closeSearch();

  void updateQuery(String query) => _ui.updateQuery(query);

  /// Adding from search: no shop, because search ignores the shop tabs.
  Future<Failure?> addFromSearch(String name) => _items.add(name: name);
}
