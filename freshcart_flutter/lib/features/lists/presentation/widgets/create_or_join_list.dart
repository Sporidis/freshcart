import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/app/router/app_router.dart';
import 'package:freshcart_flutter/core/ui/sheet/app_sheet.dart';
import 'package:freshcart_flutter/features/lists/application/last_opened_list/last_opened_list_controller.dart';
import 'package:freshcart_flutter/features/lists/application/lists/lists_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/new_list_sheet.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/text_prompt_dialog.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';

/// Opens the "New list" sheet. A top-level function, so the drawer and
/// other screens can all use it (decisions.md #63).
///
/// Takes a [ProviderContainer], not a [WidgetRef]. Why: the drawer closes
/// before the dialog is submitted. Once the drawer is closed, its `ref`
/// can't be used anymore (Riverpod throws). The container doesn't belong
/// to one widget, so it's always safe. Get it with
/// `ProviderScope.containerOf(context, listen: false)` before closing
/// anything.
Future<void> showCreateListSheet(
  BuildContext context,
  ProviderContainer container,
  Translations t,
) async {
  ShoppingList? created;
  await showAppSheet<bool>(
    context: context,
    builder: (context) => NewListSheet(
      onSubmit: (value) async => container
          .read(listsControllerProvider.notifier)
          .create(value)
          .then((r) => r.map<void>((list) => created = list)),
    ),
  );
  if (created case final list?) await _openNewList(container, list.id);
}

/// Opens the "Join a list" dialog. Works like [showCreateListSheet].
Future<void> showJoinListDialog(
  BuildContext context,
  ProviderContainer container,
  Translations t,
) async {
  ShoppingList? joined;
  await showDialog<bool>(
    context: context,
    builder: (context) => TextPromptDialog(
      title: t.lists.join,
      label: t.lists.joinCodeLabel,
      submitLabel: t.common.save,
      cancelLabel: t.common.cancel,
      capitalization: TextCapitalization.characters,
      onSubmit: (value) async => container
          .read(listsControllerProvider.notifier)
          .join(value)
          .then((r) => r.map<void>((list) => joined = list)),
    ),
  );
  if (joined case final list?) await _openNewList(container, list.id);
}

/// Opens a list the user just created or joined.
///
/// Uses the router directly, not a `BuildContext`, because the widget that
/// opened the dialog may already be gone. Also saves it as the last opened
/// list.
Future<void> _openNewList(ProviderContainer container, ListId id) async {
  container.read(appRouterProvider).go(Routes.listDetail(id));
  await container.read(lastOpenedListControllerProvider.notifier).select(id);
}
