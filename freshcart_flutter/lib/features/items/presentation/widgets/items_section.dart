import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/locale_controller.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_motion.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/core/ui/failure_state.dart';
import 'package:freshcart_flutter/core/ui/sheet/app_sheet.dart';
import 'package:freshcart_flutter/core/ui/swipe_to_delete.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_state.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/celebration/completion_celebration_card.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/delete_item_with_undo.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/done_divider.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_sheet.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_tile/item_tile.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_empty_state.dart';
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
        Positioned.fill(
          // Outside the state switch, so it survives an empty tab between
          // two full ones.
          child: _TabSwitchMotion(
            filter: s.shopFilter,
            order: [null, for (final shop in s.shops) shop.id],
            child: body,
          ),
        ),
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
    final outcome = await showAppSheet<ItemSheetOutcome>(
      context: context,
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
    final outcome = await showAppSheet<ItemSheetOutcome>(
      context: context,
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
      required int position,
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
      child: _TabSlide(
        position: position,
        child: ItemTile(
          t: t,
          item: item,
          shopColor: dotFor(item.shopId),
          // On All the row is the only sign of its shop; on a tab it's obvious.
          shopName: state.shopFilter == null
              ? state.shopFor(item.shopId)?.name
              : null,
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
            onClear: () async => report(await vm.clearChecked()),
          ),
          if (!state.doneCollapsed)
            for (final (i, item) in done.indexed)
              tileFor(item, position: open.length + 1 + i),
        ],
      ],
    );
  }
}

/// What the items area shows when there are no items: [ItemsEmptyState],
/// naming the shop on a shop tab. Both versions start adding.
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

  /// Opens the add sheet, with the selected shop if there is one.
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final shop = this.shop;
    // Scrolls, like the list it stands in for: with the ghost card it's
    // taller than a small phone's list area. Top-aligned, as in the design.
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: _floatingClusterInset),
      // On a shop tab this sits inside the shop's theme (decisions.md #73),
      // so the ghost rings and the pill's plus take the shop's colour.
      child: shop == null
          ? ItemsEmptyState(
              title: t.items.emptyTitle,
              body: t.items.emptyBody,
              actionLabel: t.items.emptyShopAction,
              onAction: onAdd,
            )
          : ItemsEmptyState(
              title: t.items.emptyShopTitle(shop: shop.name),
              body: t.items.emptyShopBody,
              actionLabel: t.items.addTo(shop: shop.name),
              onAction: onAdd,
            ),
    );
  }
}

/// Slides the rows in from the side of the tab you moved to (design v3:
/// 28px, 220ms, rows 24ms apart).
///
/// One controller for the whole list, shared through [_TabSwitchScope].
/// A row that mounts later (a newly added item) finds the animation already
/// finished and simply appears; one animation per row couldn't tell the
/// two cases apart.
class _TabSwitchMotion extends StatefulWidget {
  const _TabSwitchMotion({
    required this.filter,
    required this.order,
    required this.child,
  });

  final ShopId? filter;

  /// The tabs in strip order (null is All), to tell left from right.
  final List<ShopId?> order;
  final Widget child;

  @override
  State<_TabSwitchMotion> createState() => _TabSwitchMotionState();
}

class _TabSwitchMotionState extends State<_TabSwitchMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.listSlide + _TabSlide.step * _TabSlide.maxStagger,
    value: 1,
  );
  double _direction = 1;

  @override
  void didUpdateWidget(covariant _TabSwitchMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter == oldWidget.filter) return;
    if (AppMotion.reduced(context)) return;
    final from = widget.order.indexOf(oldWidget.filter);
    final to = widget.order.indexOf(widget.filter);
    // Moving right, the rows come in from the right.
    _direction = to >= from ? 1 : -1;
    unawaited(_controller.forward(from: 0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _TabSwitchScope(
    controller: _controller,
    direction: _direction,
    child: widget.child,
  );
}

class _TabSwitchScope extends InheritedNotifier<AnimationController> {
  const _TabSwitchScope({
    required AnimationController controller,
    required this.direction,
    required super.child,
  }) : super(notifier: controller);

  /// 1 when the rows enter from the right, -1 from the left.
  final double direction;
}

/// One row's part of [_TabSwitchMotion]: its own 220ms slice of the shared
/// animation, starting [step] later than the row above.
class _TabSlide extends StatelessWidget {
  const _TabSlide({required this.position, required this.child});

  /// The row's place in the list, for its delay.
  final int position;
  final Widget child;

  static const Duration step = Duration(milliseconds: 24);

  /// Rows below this all start together, so a long list isn't still
  /// arriving half a second later.
  static const int maxStagger = 8;
  static const double _travel = 28;

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_TabSwitchScope>();
    final controller = scope?.notifier;
    if (scope == null || controller == null || controller.isCompleted) {
      return child;
    }
    final total = controller.duration!.inMicroseconds;
    final start = (step * position.clamp(0, maxStagger)).inMicroseconds;
    final t = Interval(
      start / total,
      (start + AppMotion.listSlide.inMicroseconds) / total,
      curve: AppMotion.enter,
    ).transform(controller.value);
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(scope.direction * _travel * (1 - t), 0),
        child: child,
      ),
    );
  }
}
