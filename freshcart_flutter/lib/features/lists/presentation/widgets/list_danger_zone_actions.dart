import 'package:flutter/material.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/tokens/app_color.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

// Deleting and leaving a list — shared so `_ListMenu`'s overflow item and
// `ListSettingsScreen`'s own row are two doors into the same flow, not two
// copies of the same confirm dialog to keep in sync (the same reasoning as
// `showCreateListDialog`/`showJoinListDialog`, decisions #63).
//
// Both own only the presentation half -- the dialog, the navigation, the
// snackbar. The write itself comes in as a callback from the caller's view
// model, so this file never needs to know which controller performs it.

/// Deleting names the list, its member count and its item count, and is not
/// undoable.
///
/// [itemCount] is a snapshot: the dialog is built once, when it opens, and
/// does not need to react to a count that changes while it is up.
///
/// A dialog rather than a snackbar with an undo, because there is nothing to
/// undo: this one is genuinely permanent, so it is worth interrupting for.
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
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.destructive,
            foregroundColor: Colors.white,
          ),
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

/// Leaving a list — a non-owner's equivalent of [confirmDeleteList]. The
/// list carries on for everyone else; only membership ends.
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
        FilledButton(
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
