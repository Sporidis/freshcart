import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app/router/app_router.dart';
import 'package:freshcart_flutter/core/ui/destructive_button.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

// Delete and leave a list. Used by both the list's "..." menu and list
// settings, so the dialogs are the same in both (decisions.md #63).
//
// These functions only handle the UI (dialog, navigation, snackbar). The
// actual delete/leave is passed in as a callback by the caller.

/// Asks "are you sure?" before deleting a list, showing the list name, how
/// many members and how many items.
///
/// [itemCount] is read once, when the dialog opens.
///
/// A dialog (not a snackbar with Undo), because deleting can't be undone.
Future<void> confirmDeleteList(
  BuildContext context, {
  required ShoppingList list,
  required int itemCount,
  required Translations t,
  required Future<Failure?> Function() delete,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t.lists.deleteConfirmTitle(name: list.name)),
      content: Text(
        t.lists.deleteConfirmBody(items: itemCount, n: list.members.length),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(t.common.cancel),
        ),
        DestructiveButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(t.lists.deleteForEveryone),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final failure = await delete();
  if (!context.mounted) return;
  if (failure == null) {
    context.go(Routes.lists);
  } else {
    showFailureSnackBar(context, failure: failure, t: t);
  }
}

/// Asks "are you sure?" before leaving a list. Like [confirmDeleteList],
/// but for members. The list still exists for the others.
Future<void> confirmLeaveList(
  BuildContext context, {
  required ShoppingList list,
  required Translations t,
  required Future<Failure?> Function() leave,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t.lists.leaveConfirmTitle),
      content: Text(t.lists.leaveConfirmBody(name: list.name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(t.common.cancel),
        ),
        // Red, like delete: to come back you'd need a new invite code.
        // (The design has no confirm here; we added one, decisions.md #104.)
        DestructiveButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(t.lists.leave),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final failure = await leave();
  if (!context.mounted) return;
  if (failure == null) {
    context.go(Routes.lists);
  } else {
    showFailureSnackBar(context, failure: failure, t: t);
  }
}
