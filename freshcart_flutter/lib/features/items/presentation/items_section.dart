import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/error/failure_messages.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/theme/hex_color_x.dart';
import 'package:freshcart_flutter/core/ui/empty_state.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/features/items/application/items_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_screen_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_screen_state.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/celebration/completion_celebration_card.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/done_divider.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_sheet.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/item_tile.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/quick_add/quick_add_bar.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/search/search_results.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// A list's items area: the rows (or search results, or an empty state),
/// with the completion celebration and the add control floating on top.
///
/// Pure UI: every derivation and multi-step action lives in
/// [ItemsScreenController]. What stays here is what needs a `BuildContext` --
/// sheets and snackbars. The header (title, selection and search actions)
/// belongs to `ListDetailScreen`, which reads the same view model.
///
/// Multi-select and rearrange are both entered from a row's hold-menu
/// ("Select more…" / "Rearrange list") rather than long-press directly,
/// since that gesture already opens the menu.
class ItemsSection extends ConsumerWidget {
  const ItemsSection({required this.list, super.key});

  final ShoppingList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final s = ref.watch(itemsScreenControllerProvider(list));
    final vm = ref.read(itemsScreenControllerProvider(list).notifier);

    void report(Failure? failure, {VoidCallback? onRetry}) {
      if (failure == null || !context.mounted) return;
      // A failed write is the snackbar tier: the screen behind it is still
      // usable, so it gets a message and a way to retry, not a replacement.
      showFailureSnackBar(context, failure: failure, t: t, onRetry: onRetry);
    }

    Color? dotFor(ShopId? shopId) {
      final shop = s.shopFor(shopId);
      return shop?.color.toColor();
    }

    Future<void> openEditSheet(ShoppingItem item) async {
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

    // QuickAddBar's onOpenDetails contract: return whether something was
    // actually added, so it knows whether to clear/collapse itself or leave
    // the typed text in place for a retry.
    Future<bool> openAddSheet(String initialName) async {
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

    Future<bool> quickAdd(String name) async {
      final failure = await vm.quickAdd(name);
      report(failure);
      return failure == null;
    }

    final loadFailure = s.loadFailure;

    // A Stack, not a docked bottom bar: the design's FAB floats over the
    // list rather than shrinking it to make room. _ItemList carries its own
    // bottom padding so its last rows clear the floating cluster.
    return Stack(
      children: [
        Positioned.fill(
          child: loadFailure != null
              ? Center(child: Text(loadFailure.toMessage(t)))
              : s.isLoading
              ? const Center(child: CircularProgressIndicator())
              // Search bypasses the shop filter and the open/done split
              // entirely (§16: "one flat list across all shops").
              : s.mode == ItemsMode.search
              ? SearchResults(
                  // Not 'search' -- the app bar's own search TextField
                  // already owns that key, and both are mounted at once.
                  key: const ValueKey('search-results'),
                  list: list,
                  allItems: s.allItems,
                  query: s.searchQuery,
                  t: t,
                  controller: ref.read(
                    itemsControllerProvider(list.id).notifier,
                  ),
                  report: report,
                )
              : s.isEmpty
              ? _ItemsEmptyState(shop: s.activeShop, t: t)
              : _ItemList(
                  state: s,
                  vm: vm,
                  t: t,
                  dotFor: dotFor,
                  report: report,
                  onEdit: openEditSheet,
                ),
        ),
        // Neither the celebration nor the add control has anything to do
        // while selecting, searching or rearranging -- selection has its own
        // contextual bar in the app bar, and search offers its own "Add to
        // list" inside its no-results state.
        if (s.mode == ItemsMode.browse && !s.isLoading)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (s.showCelebration)
                  CompletionCelebrationCard(
                    list: list,
                    itemCount: s.allItems.length,
                    shopColors: s.shops.isEmpty
                        ? AppColors.presetShopColors
                        : [for (final shop in s.shops) shop.color.toColor()],
                    t: t,
                    report: report,
                  ),
                QuickAddBar(
                  listId: list.id,
                  t: t,
                  activeShopName: s.activeShop?.name,
                  firstRun: s.firstRun,
                  onQuickAdd: quickAdd,
                  onOpenDetails: openAddSheet,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Clears the floating add control that sits on top of the items area, so
/// neither the last row nor the empty-state copy renders underneath it.
const double _floatingClusterInset = 84;

/// The rows themselves, split into open and Done -- checked items collect
/// below a collapsible [DoneDivider] with a "Clear checked" action.
///
/// Selection and rearrange only ever apply to open rows: a settled, checked
/// item has its own bulk action already ("Clear checked").
class _ItemList extends StatelessWidget {
  const _ItemList({
    required this.state,
    required this.vm,
    required this.t,
    required this.dotFor,
    required this.report,
    required this.onEdit,
  });

  final ItemsScreenState state;
  final ItemsScreenController vm;
  final Translations t;
  final Color? Function(ShopId?) dotFor;
  final void Function(Failure?, {VoidCallback? onRetry}) report;
  final void Function(ShoppingItem) onEdit;

  @override
  Widget build(BuildContext context) {
    final selectionMode = state.mode == ItemsMode.select;

    Widget tileFor(
      ShoppingItem item, {
      bool selectable = false,
      int? index,
    }) => ItemTile(
      t: t,
      key: ValueKey(item.id.value),
      item: item,
      shopColor: dotFor(item.shopId),
      onToggle: () async => report(await vm.toggle(item)),
      onEdit: () => onEdit(item),
      onDelete: () => vm.swipeDelete(item),
      onQuantityChanged: (quantity) async =>
          report(await vm.setQuantity(item, quantity)),
      selected: selectable && state.selection.contains(item.id),
      selectionMode: selectable && selectionMode,
      onSelectionToggle: selectable ? () => vm.toggleSelection(item.id) : null,
      onSelectMore: selectable ? () => vm.toggleSelection(item.id) : null,
      // On "All", the menu's "Rearrange list" row just closes the menu.
      onRearrange: selectable && state.canRearrange ? vm.startRearrange : null,
      dragHandle: index == null
          ? null
          : ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle, size: 16),
            ),
      checkedByMember: item.checkedBy == null
          ? null
          : state.list.memberFor(item.checkedBy!),
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

/// The empty state for the items area, in its two forms, since the design
/// draws them differently (an empty shop tab names the shop and
/// tints to its colour; an empty list points at adding the first item).
class _ItemsEmptyState extends StatelessWidget {
  const _ItemsEmptyState({required this.shop, required this.t});

  /// The filtered-to shop, or null on "All" (or a filter whose shop hasn't
  /// loaded) -- both of which get the generic copy.
  final Shop? shop;
  final Translations t;

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
            ),
    );
  }
}
