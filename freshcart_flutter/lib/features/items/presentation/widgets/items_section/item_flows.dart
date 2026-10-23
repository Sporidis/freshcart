import 'dart:async';
import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/ui/feedback/failure_snack_bar.dart';
import 'package:freshcart_flutter/core/ui/sheet/app_sheet.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_controller.dart';
import 'package:freshcart_flutter/features/items/application/items_section/items_section_state.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_sheet/item_sheet.dart';
import 'package:freshcart_flutter/features/items/presentation/widgets/item_sheet/item_sheet_outcome.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Helper for the actions that need a `BuildContext` (sheets, snackbars),
/// on top of the controller's actions. Made fresh on every build, so it
/// always has the current state.
class ItemFlows {
  const ItemFlows({
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
  void report(Failure? failure, {VoidCallback? onRetry}) =>
      showFailureSnackBar(context, failure: failure, t: t, onRetry: onRetry);

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
        listName: s.list.name,
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
