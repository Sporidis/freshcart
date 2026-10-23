import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/ui/feedback/undo_toast.dart';
import 'package:freshcart_flutter/core/ui/motion/swipe_to_delete.dart';
import 'package:freshcart_flutter/features/items/application/items/items_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_mode.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_state.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/delete_item_with_undo.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/done_divider.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/arrival_flash.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/item_tile.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/pending_edge.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_section/floating_cluster.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_section/motion/arrival_scope.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_section/motion/glide.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_section/motion/tab_slide.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// The rows: open items first, then checked items under a [DoneDivider]
/// (which can fold them away and has "Clear checked").
///
/// Only open rows can be selected or rearranged. Checked rows already have
/// "Clear checked".
class ItemList extends StatelessWidget {
  const ItemList({
    super.key,
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
      delete: vm.removeWithUndo,
      t: t,
    );

    Widget tileFor(
      ShoppingItem item, {
      required int position,
      bool selectable = false,
      bool inDone = false,
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
      // No "are you sure?". The row goes now, and the toast's Undo can bring
      // it back.
      onSwipe: () async => true,
      onDismissed: () => deleteWithUndo(item),
      child: TabSlide(
        position: position,
        child: Glide(
          // The batch that just settled glides down in tap order; anything
          // else that moves (rows closing a gap, an unticked row going back
          // up) reflows without a delay.
          delay: inDone && state.lastSettled.contains(item.id)
              ? AppMotion.batchStagger * state.lastSettled.indexOf(item.id)
              : Duration.zero,
          duration: inDone && state.lastSettled.contains(item.id)
              ? AppMotion.batchMove
              : AppMotion.reflow,
          child: PendingEdge(
            // v3 Flow 07: a dashed edge while this row's change waits
            // in the offline queue.
            pending: item.pending,
            index: position,
            child: ArrivalFlash(
              isNew: ArrivalScope.isNew(context, item.id),
              mine: ArrivalScope.isMine(context, item),
              color: dotFor(item.shopId),
              child: ItemTile(
                t: t,
                item: item,
                inDone: inDone,
                shopColor: dotFor(item.shopId),
                // On All the row is the only sign of its shop; on a tab it's
                // obvious.
                shopName: state.shopFilter == null
                    ? state.shopFor(item.shopId)?.name
                    : null,
                // Saved at once, but held in place until the ticks settle.
                onToggle: () async => report(
                  await vm.toggle(
                    item,
                    settleAfter: AppMotion.reduced(context)
                        ? AppMotion.checkSettleReduced
                        : AppMotion.checkSettle,
                  ),
                ),
                onEdit: () => onEdit(item),
                shops: state.shops,
                onMove: (shopId) async =>
                    report(await vm.moveItem(item, shopId)),
                onDelete: () => deleteWithUndo(item),
                onQuantityChanged: (quantity) async =>
                    report(await vm.setQuantity(item, quantity)),
                selected: selectable && state.selection.contains(item.id),
                selectionMode: selectable && selectionMode,
                onSelectionToggle: selectable
                    ? () => vm.toggleSelection(item.id)
                    : null,
                onSelectMore: selectable
                    ? () => vm.toggleSelection(item.id)
                    : null,
                // Only open rows (not checked ones) can start rearranging.
                onRearrange: selectable ? vm.startRearrange : null,
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
            ),
          ),
        ),
      ),
    );

    final open = state.openItems;
    final done = state.doneItems;

    return ListView(
      padding: const EdgeInsets.only(bottom: FloatingCluster.inset),
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
                tileFor(item, position: index, index: index),
            ],
          )
        else
          for (final (i, item) in open.indexed)
            tileFor(item, position: i, selectable: true),
        if (done.isNotEmpty) ...[
          DoneDivider(
            label: t.items.doneCount(n: done.length),
            collapsed: state.doneCollapsed,
            onToggle: vm.toggleDoneCollapsed,
            clearLabel: t.items.clear,
            onClear: () {
              final (:count, :undo) = vm.clearDoneWithUndo();
              showUndoToast(
                context,
                message: t.items.cleared(n: count),
                t: t,
                onUndo: undo,
                // Visible exactly as long as Undo still works.
                duration: ItemsController.swipeUndoWindow,
              );
            },
          ),
          if (!state.doneCollapsed)
            for (final (i, item) in done.indexed)
              tileFor(item, position: open.length + 1 + i, inDone: true),
        ],
      ],
    );
  }
}
