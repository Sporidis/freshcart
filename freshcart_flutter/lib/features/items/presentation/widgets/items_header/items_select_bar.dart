import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/l10n/translations_provider.dart';
import 'package:freshcart_flutter/core/ui/feedback/failure_snack_bar.dart';
import 'package:freshcart_flutter/core/ui/feedback/undo_toast.dart';
import 'package:freshcart_flutter/features/items/application/items/items_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_controller.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_header/mode_bar.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/items_header/mode_bar_pill.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/move_to_shop_sheet.dart';

/// The header while selecting items: "{n} selected", Move and Delete, each
/// with an undo toast.
class ItemsSelectBar extends ConsumerWidget {
  /// Creates the bar for [list]'s selection.
  const ItemsSelectBar({required this.list, super.key});

  final ShoppingList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final items = ref.watch(itemsSectionControllerProvider(list));
    final vm = ref.read(itemsSectionControllerProvider(list).notifier);
    final hasSelection = items.selection.isNotEmpty;

    void report(Failure? failure) =>
        showFailureSnackBar(context, failure: failure, t: t);

    Future<void> moveSelected() async {
      // Cancelled (null): keep the selection as it was.
      final outcome = await showMoveToShopSheet(
        context,
        shops: items.shops,
        t: t,
      );
      if (outcome == null) return;
      final previous = vm.shopsOfSelection();
      final failure = await vm.moveSelected(outcome.shopId);
      if (!context.mounted) return;
      if (failure != null) return report(failure);
      final to = outcome.shopId;
      showUndoToast(
        context,
        message: t.items.moved(
          n: previous.length,
          shop: to == null
              ? t.shops.none
              : items.shopFor(to)?.name ?? t.shops.none,
        ),
        t: t,
        onUndo: () async => report(await vm.moveBack(previous)),
      );
    }

    void deleteSelected() {
      final (:count, :undo) = vm.deleteSelectedWithUndo();
      showUndoToast(
        context,
        message: t.items.deleted(n: count),
        t: t,
        onUndo: undo,
        // Visible exactly as long as Undo still works.
        duration: ItemsController.swipeUndoWindow,
      );
    }

    return ModeBar(
      title: Text(t.items.selectedCount(n: items.selection.length)),
      onClose: vm.clearSelection,
      closeLabel: t.common.cancel,
      actions: [
        ModeBarPill(
          label: t.common.move,
          onTap: hasSelection ? moveSelected : null,
        ),
        ModeBarPill(
          label: t.common.delete,
          destructive: true,
          onTap: hasSelection ? deleteSelected : null,
        ),
      ],
    );
  }
}
