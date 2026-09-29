import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/features/lists/application/list_detail_screen_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/list_danger_zone_actions.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// The list's overflow menu.
///
/// Owners and members see different verbs on purpose: leaving takes you out of
/// a list that carries on without you, while deleting ends it for the whole
/// household. Offering the wrong one is how someone destroys a shared list
/// meaning to walk away from it.
class ListMenu extends ConsumerWidget {
  const ListMenu({required this.list, required this.t, super.key});

  final ShoppingList list;
  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = ref.watch(
      listDetailScreenControllerProvider(list.id).select((s) => s.isOwner),
    );
    final vm = ref.read(listDetailScreenControllerProvider(list.id).notifier);

    return PopupMenuButton<void>(
      itemBuilder: (context) => [
        // Household itself is reached through the avatar in the app bar now,
        // not the menu -- one door, not two, into the same screen.
        PopupMenuItem<void>(
          onTap: () => context.go(Routes.manageShops(list.id)),
          child: Text(t.shops.manage),
        ),
        // Owners delete, members leave -- one verb each, never both. The
        // wrong one on the wrong account is how a shared list gets destroyed
        // by somebody who only meant to walk away from it.
        if (isOwner)
          PopupMenuItem<void>(
            onTap: () => confirmDeleteList(
              context,
              list: list,
              itemCount: vm.itemCountForDialog(),
              t: t,
              delete: vm.deleteList,
            ),
            child: Text(t.lists.delete),
          )
        else
          PopupMenuItem<void>(
            onTap: () => confirmLeaveList(
              context,
              list: list,
              t: t,
              leave: vm.leaveList,
            ),
            child: Text(t.lists.leave),
          ),
      ],
    );
  }
}
