import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/items/application/items/items_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Deletes [item] the undoable way: hidden at once, committed only after
/// [ItemsController.swipeUndoWindow], with an "Undo" snackbar for exactly
/// that long (Motion spec §10).
///
/// The one path every item delete takes -- the swipe, the hold menu's
/// Delete, and the same two in search results. [delete] is the caller's
/// view-model `swipeDelete`, which hands back the undo action; before this
/// existed, every caller dropped that action on the floor, so a deleted
/// item quietly vanished four seconds later with no way back.
void deleteItemWithUndo(
  BuildContext context, {
  required ShoppingItem item,
  required void Function() Function(ShoppingItem) delete,
  required Translations t,
}) {
  final undo = delete(item);
  ScaffoldMessenger.of(context)
    // One at a time, newest wins -- same rule as showFailureSnackBar.
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(t.items.itemRemoved(name: item.name)),
        // Exactly the window the delete is actually held for: a snackbar
        // that outlived it would offer an undo that no longer works.
        duration: ItemsController.swipeUndoWindow,
        action: SnackBarAction(label: t.common.undo, onPressed: undo),
      ),
    );
}
