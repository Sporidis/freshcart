import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/core/ui/empty_state.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/core/ui/failure_state.dart';
import 'package:freshcart_flutter/core/ui/swipe_to_delete.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_state.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/celebration/completion_celebration_card.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/delete_item_with_undo.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/done_divider.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_sheet.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/item_tile.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/quick_add/quick_add_bar.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/search/search_results.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The items area of a list: the rows (or search results, or an empty
/// state), with the "all done" card and the add button floating on top.
///
/// Only UI. The logic is in [ItemsSectionController]. Here are only things
/// that need a `BuildContext`: sheets and snackbars. The app bar is in
/// `ListDetailScreen`.
///
/// Select and rearrange mode start from the hold menu ("Select more…" /
/// "Rearrange list"), because holding already opens the menu.
class ItemsSection extends ConsumerWidget {
  const ItemsSection({required this.list, super.key});

  final ShoppingList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final s = ref.watch(itemsSectionControllerProvider(list));
    final vm = ref.read(itemsSectionControllerProvider(list).notifier);
    final flows = _ItemFlows(context: context, s: s, vm: vm, t: t);

    Color? dotFor(ShopId? shopId) => s.shopFor(shopId)?.color.toColor();

    final body = switch (s) {
      ItemsSectionState(loadFailure: final failure?) => FailureState(
        failure: failure,
        t: t,
        action: ElevatedButton(
          onPressed: vm.retryLoad,
          child: Text(t.common.retry),
        ),
      ),
      ItemsSectionState(isLoading: true) => const Center(
        child: CircularProgressIndicator(),
      ),
      // Search shows one list across all shops, without the open/done split.
      ItemsSectionState(mode: ItemsMode.search) => SearchResults(
        // Not 'search': the search field in the app bar already uses that
        // key, and both exist at the same time.
        key: const ValueKey('search-results'),
        state: s,
        vm: vm,
        t: t,
        dotFor: dotFor,
        onEdit: flows.edit,
        report: flows.report,
      ),
      ItemsSectionState(isEmpty: true) => _ItemsEmptyState(
        shop: s.activeShop,
        t: t,
        onAdd: () => unawaited(flows.addWithDetails('')),
      ),
      _ => _ItemList(
        state: s,
        vm: vm,
        t: t,
        dotFor: dotFor,
        report: flows.report,
        onEdit: flows.edit,
      ),
    };

    // A Stack, so the add button floats over the list (the list doesn't
    // get smaller). The list has bottom padding so the last row isn't
    // hidden under the button.
    return Stack(
      children: [
        Positioned.fill(child: body),
        // No "all done" card and no add button while selecting, searching
        // or rearranging. (Search has its own "Add to list" button.)
        if (s.mode == ItemsMode.browse && !s.isLoading)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _FloatingCluster(s: s, vm: vm, flows: flows, t: t),
          ),
      ],
    );
  }
}

/// Helper for the actions that need a `BuildContext` (sheets, snackbars),
/// on top of the controller's actions. Made fresh on every build, so it
/// always has the current state.
class _ItemFlows {
  const _ItemFlows({
    required this.context,
    required this.s,
    required this.vm,
    required this.t,
  });

  final BuildContext context;
  final ItemsSectionState s;
  final ItemsSectionController vm;
  final Translations t;

  /// Shows a failed save as a snackbar (with Retry). The screen is still
  /// fine, so no full error screen.
  void report(Failure? failure, {VoidCallback? onRetry}) {
    if (failure == null || !context.mounted) return;
    showFailureSnackBar(context, failure: failure, t: t, onRetry: onRetry);
  }

  Future<void> edit(ShoppingItem item) async {
    final outcome = await showModalBottomSheet<ItemSheetOutcome>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ItemSheet.edit(item: item, shops: s.shops, t: t),
    );
    switch (outcome) {
      case null:
        return;
      case ItemSheetRemove():
        report(await vm.remove(item));
      case ItemSheetSave(
        :final name,
        :final quantity,
        :final shopId,
        :final noteText,
      ):
        report(
          await vm.edit(
            item,
            name: name,
            quantity: quantity,
            shopId: shopId,
            noteText: noteText,
          ),
        );
    }
  }

  /// Opens the item sheet. Returns true if an item was added. Then
  /// QuickAddBar clears and closes; if false, it keeps the typed text.
  Future<bool> addWithDetails(String initialName) async {
    final outcome = await showModalBottomSheet<ItemSheetOutcome>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ItemSheet.add(
        initialName: initialName,
        shops: s.shops,
        t: t,
        initialShopId: s.shopFilter,
      ),
    );
    if (outcome is! ItemSheetSave) return false;
    final failure = await vm.add(
      name: outcome.name,
      quantity: outcome.quantity,
      shopId: outcome.shopId,
      noteText: outcome.noteText,
    );
    report(failure);
    return failure == null;
  }

  /// Quick add. Returns true if it worked (same as [addWithDetails]).
  Future<bool> quickAdd(String name) async {
    final failure = await vm.quickAdd(name);
    report(failure);
    return failure == null;
  }

  /// "Make it x{n}" on the "already on the list" card. Returns true if it
  /// worked. If false, the card stays so the user can try again.
  Future<bool> bumpDuplicate(ShoppingItem item) async {
    final failure = await vm.bumpQuantity(item);
    report(failure);
    return failure == null;
  }
}

/// What floats over the rows normally: the "all done" card (if needed)
/// and the add button.
class _FloatingCluster extends StatelessWidget {
  const _FloatingCluster({
    required this.s,
    required this.vm,
    required this.flows,
    required this.t,
  });

  final ItemsSectionState s;
  final ItemsSectionController vm;
  final _ItemFlows flows;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (s.showCelebration)
          CompletionCelebrationCard(
            list: s.list,
            itemCount: s.allItems.length,
            shopColors: s.shops.isEmpty
                ? AppColors.presetShopColors
                : [for (final shop in s.shops) shop.color.toColor()],
            t: t,
            report: flows.report,
            onKeep: vm.dismissCelebration,
            onClear: vm.clearChecked,
          ),
        QuickAddBar(
          listId: s.list.id,
          t: t,
          activeShopName: s.activeShop?.name,
          firstRun: s.firstRun,
          onQuickAdd: flows.quickAdd,
          onOpenDetails: flows.addWithDetails,
          findDuplicate: (name) => s.duplicateFor(name, s.shopFilter),
          onBumpDuplicate: flows.bumpDuplicate,
        ),
      ],
    );
  }
}

/// Bottom padding, so the last row (or empty-state text) isn't hidden under
/// the floating add button.
const double _floatingClusterInset = 84;

/// The rows: open items first, then checked items under a [DoneDivider]
/// (which can fold them away and has "Clear checked").
///
/// Only open rows can be selected or rearranged. Checked rows already have
/// "Clear checked".
class _ItemList extends StatelessWidget {
  const _ItemList({
    required this.state,
    required this.vm,
    required this.t,
    required this.dotFor,
    required this.report,
    required this.onEdit,
  });

  final ItemsSectionState state;
  final ItemsSectionController vm;
  final Translations t;
  final Color? Function(ShopId?) dotFor;
  final void Function(Failure?, {VoidCallback? onRetry}) report;
  final void Function(ShoppingItem) onEdit;

  @override
  Widget build(BuildContext context) {
    final selectionMode = state.mode == ItemsMode.select;

    void deleteWithUndo(ShoppingItem item) => deleteItemWithUndo(
      context,
      item: item,
      delete: vm.swipeDelete,
      t: t,
    );

    Widget tileFor(
      ShoppingItem item, {
      bool selectable = false,
      int? index,
    }) => SwipeToDelete(
      // The key goes on this outer widget: ReorderableListView needs a key
      // on each direct child.
      key: ValueKey(item.id.value),
      dismissKey: ValueKey('swipe-${item.id.value}'),
      semanticLabel: t.common.delete,
      // No swipe-to-delete in select or rearrange mode, so it doesn't fight
      // with dragging or selecting.
      enabled: !selectionMode && state.mode != ItemsMode.rearrange,
      // No "are you sure?". The row goes now, and the snackbar's Undo can
      // bring it back.
      onSwipe: () async => true,
      onDismissed: () => deleteWithUndo(item),
      child: ItemTile(
        t: t,
        item: item,
        shopColor: dotFor(item.shopId),
        onToggle: () async => report(await vm.toggle(item)),
        onEdit: () => onEdit(item),
        onDelete: () => deleteWithUndo(item),
        onQuantityChanged: (quantity) async =>
            report(await vm.setQuantity(item, quantity)),
        selected: selectable && state.selection.contains(item.id),
        selectionMode: selectable && selectionMode,
        onSelectionToggle: selectable
            ? () => vm.toggleSelection(item.id)
            : null,
        onSelectMore: selectable ? () => vm.toggleSelection(item.id) : null,
        // Only open rows (not checked ones) can start rearranging.
        onRearrange: selectable && state.canRearrange
            ? vm.startRearrange
            : null,
        dragHandle: index == null
            ? null
            : ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle, size: 16),
              ),
        checkedByMember: item.checkedBy == null
            ? null
            : state.list.memberFor(item.checkedBy!),
      ),
    );

    final open = state.openItems;
    final done = state.doneItems;

    return ListView(
      padding: const EdgeInsets.only(bottom: _floatingClusterInset),
      children: [
        if (state.mode == ItemsMode.rearrange)
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (oldIndex, newIndex) => unawaited(
              vm.reorderOpen(oldIndex, newIndex).then(report),
            ),
            children: [
              for (final (index, item) in open.indexed)
                tileFor(item, index: index),
            ],
          )
        else
          for (final item in open) tileFor(item, selectable: true),
        if (done.isNotEmpty) ...[
          DoneDivider(
            label: t.items.doneCount(n: done.length),
            collapsed: state.doneCollapsed,
            onToggle: vm.toggleDoneCollapsed,
            clearLabel: t.items.clearChecked,
            onClear: () async => report(await vm.clearChecked()),
          ),
          if (!state.doneCollapsed)
            for (final item in done) tileFor(item),
        ],
      ],
    );
  }
}

/// What the items area shows when there are no items. Two versions:
/// - an empty shop tab: names the shop, in its colour, with an add button;
/// - an empty list: points at adding the first item.
class _ItemsEmptyState extends StatelessWidget {
  const _ItemsEmptyState({
    required this.shop,
    required this.t,
    required this.onAdd,
  });

  /// The selected shop, or null on "All" (or if the shop hasn't loaded).
  /// Null shows the general text.
  final Shop? shop;
  final Translations t;

  /// Opens the add sheet with the selected shop. Only on an empty shop tab.
  /// A brand-new list has no button here; the add button pulses instead.
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final shop = this.shop;
    return Padding(
      padding: const EdgeInsets.only(bottom: _floatingClusterInset),
      child: shop == null
          ? EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: t.items.emptyTitle,
              body: t.items.emptyBody,
            )
          : EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: t.items.emptyShopTitle(shop: shop.name),
              body: t.items.emptyShopBody,
              tint: shop.color.toColor(),
              // Automatically in the shop's colour: this is inside the shop's
              // theme (decisions.md #73), so a normal FilledButton uses it.
              action: FilledButton(
                onPressed: onAdd,
                child: Text(t.items.emptyShopAction),
              ),
            ),
    );
  }
}
