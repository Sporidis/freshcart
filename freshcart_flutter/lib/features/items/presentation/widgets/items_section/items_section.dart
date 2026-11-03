import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/translations_provider.dart';
import 'package:freshcart_flutter/core/theme/tokens/hex_color_x.dart';
import 'package:freshcart_flutter/core/ui/feedback/empty_state.dart';
import 'package:freshcart_flutter/core/ui/feedback/undo_toast.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_mode.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_state.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_section/floating_cluster.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_section/item_flows.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_section/item_list.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_section/items_section_empty_state.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_section/motion/arrival_scope.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_section/motion/scale_out.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_section/motion/tab_switch_motion.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/search/search_results.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/list_failure_state.dart';
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
    final flows = ItemFlows(context: context, s: s, vm: vm, t: t);

    // A burst of ticks just settled into Done: one toast for all of it.
    ref.listen(
      itemsSectionControllerProvider(list).select((s) => s.settleCount),
      (previous, next) {
        if (previous == null || next <= previous) return;
        _showSettledToast(
          context,
          ref.read(itemsSectionControllerProvider(list)),
          vm,
          t,
        );
      },
    );

    Color? dotFor(ShopId? shopId) => s.shopFor(shopId)?.color.toColor();

    final body = switch (s) {
      // Offline, and this phone never saved the list: a state, not an
      // error. Not the empty state either, since the list may have items.
      // No Retry: the items load by themselves once the server answers,
      // and anything added meanwhile shows at once (it's queued).
      ItemsSectionState(loadFailure: NetworkFailure()) => EmptyState(
        icon: Icons.wifi_off,
        title: t.items.offlineTitle,
        body: t.items.offlineBody,
      ),
      ItemsSectionState(loadFailure: final failure?) => ListFailureState(
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
      ItemsSectionState(isEmpty: true) => ItemsSectionEmptyState(
        shop: s.activeShop,
        t: t,
        onAdd: () => unawaited(flows.addWithDetails('')),
      ),
      _ => ItemList(
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
          child: ArrivalScope(
            // Null while loading, so the first load isn't "everything
            // arrived".
            items: s.isLoading ? null : s.allItems,
            me: s.me?.userId,
            child: TabSwitchMotion(
              filter: s.shopFilter,
              order: [null, for (final shop in s.shops) shop.id],
              child: body,
            ),
          ),
        ),
        // No "all done" card and no add button while selecting, searching
        // or rearranging. (Search has its own "Add to list" button.) In v3
        // it scales out to 0.6 as the mode starts, rather than vanishing.
        if (!s.isLoading)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ScaleOut(
              visible: s.mode == ItemsMode.browse,
              child: FloatingCluster(s: s, vm: vm, flows: flows, t: t),
            ),
          ),
      ],
    );
  }
}

/// The toast after a burst of ticks lands in Done: "Pasta checked off",
/// "3 items checked off", or, when that emptied the tab, "Everything is in
/// the basket". Undo unchecks the whole burst.
void _showSettledToast(
  BuildContext context,
  ItemsSectionState s,
  ItemsSectionController vm,
  Translations t,
) {
  final checked = {
    for (final item in s.allItems)
      if (item.isChecked) item.id: item,
  };
  // A tick the server refused is unchecked again by now; leave it out.
  final ids = [
    for (final id in s.lastSettled)
      if (checked.containsKey(id)) id,
  ];
  if (ids.isEmpty) return;
  final shop = s.activeShop;
  final message = switch ((s.openItems.isEmpty, ids.length)) {
    (true, _) when shop != null => t.items.allInShop(shop: shop.name),
    (true, _) => t.items.allInBasket,
    (false, 1) => t.items.checkedOffOne(name: checked[ids.single]!.name),
    (false, final n) => t.items.checkedOff(n: n),
  };
  showUndoToast(
    context,
    message: message,
    t: t,
    tick: true,
    onUndo: () => unawaited(vm.undoSettledBatch(ids)),
  );
}
