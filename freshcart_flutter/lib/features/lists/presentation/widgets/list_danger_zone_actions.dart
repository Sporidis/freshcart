import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/core/theme/app_color.dart';
import 'package:freshcart_flutter/core/ui/failure_snack_bar.dart';
import 'package:freshcart_flutter/features/items/application/items_controller.dart';
import 'package:freshcart_flutter/features/lists/application/lists_controller.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

// Deleting and leaving a list — shared so `_ListMenu`'s overflow item and
// `ListSettingsScreen`'s own row are two doors into the same flow, not two
// copies of the same confirm dialog to keep in sync (the same reasoning as
// `showCreateListDialog`/`showJoinListDialog`, decisions #63).
//
// Both take a `WidgetRef` rather than a `ProviderContainer`: unlike the
// drawer's create/join rows (decisions #65), nothing here pops the calling
// screen before the dialog resolves — the confirm dialog sits on top of
// whichever screen opened it, which stays mounted throughout.

/// Deleting names the list, its member count and its item count, and is not
/// undoable.
///
/// The item count comes from [itemsControllerProvider] — read, not watched:
/// the dialog is built once, when it opens, and does not need to react to a
/// count that changes while it is up.
///
/// A dialog rather than a snackbar with an undo, because there is nothing to
/// undo: this one is genuinely permanent, so it is worth interrupting for.
Future<void> confirmDeleteList(
  BuildContext context,
  WidgetRef ref,
  ShoppingList list,
  Translations t,
) async {
  final itemCount =
      ref.read(itemsControllerProvider(list.id)).dataOrNull?.length ?? 0;
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

  final result = await ref
      .read(listsControllerProvider.notifier)
      .delete(list.id);
  if (!context.mounted) return;
  switch (result) {
    case Ok<void>():
      context.go(Routes.lists);
    case Err<void>(:final failure):
      showFailureSnackBar(context, failure: failure, t: t);
  }
}

/// Leaving a list — a non-owner's equivalent of [confirmDeleteList]. The
/// list carries on for everyone else; only membership ends.
Future<void> confirmLeaveList(
  BuildContext context,
  WidgetRef ref,
  ShoppingList list,
  Translations t,
) async {
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

  final result = await ref
      .read(listsControllerProvider.notifier)
      .leave(list.id);
  if (!context.mounted) return;
  switch (result) {
    case Ok<void>():
      context.go(Routes.lists);
    case Err<void>(:final failure):
      showFailureSnackBar(context, failure: failure, t: t);
  }
}
