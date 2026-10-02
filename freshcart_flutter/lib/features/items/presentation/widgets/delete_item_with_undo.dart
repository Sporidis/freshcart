import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/ui/undo_toast.dart';
import 'package:freshcart_flutter/features/items/application/items/items_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Deletes [item] with an Undo option.
///
/// The item disappears right away, and an Undo toast shows. The real
/// delete happens after [ItemsController.swipeUndoWindow], unless Undo is
/// tapped.
///
/// Every way of deleting an item uses this (swipe, hold menu, search).
/// [delete] is the controller's `swipeDelete`, which returns the undo
/// function.
void deleteItemWithUndo(
  BuildContext context, {
  required ShoppingItem item,
  required void Function() Function(ShoppingItem) delete,
  required Translations t,
}) {
  final undo = delete(item);
  showUndoToast(
    context,
    message: t.items.itemRemoved(name: item.name),
    t: t,
    onUndo: undo,
    // Shown exactly as long as Undo still works.
    duration: ItemsController.swipeUndoWindow,
  );
}
