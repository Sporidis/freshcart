import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/features/lists/application/list_detail_screen/list_detail_screen_controller.dart';
import 'package:freshcart_flutter/features/lists/presentation/widgets/list_danger_zone_actions.dart';
import 'package:freshcart_l10n/freshcart_l10n.dart';
import 'package:go_router/go_router.dart';

/// The "..." menu on a list.
///
/// The owner sees "Delete", members see "Leave". Leaving only removes you.
/// Deleting removes the list for everyone. Showing the wrong one could make
/// someone delete a shared list when they only wanted to leave.
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
        // No "Household" here: the avatar in the app bar opens it.
        PopupMenuItem<void>(
          onTap: () => context.go(Routes.manageShops(list.id)),
          child: Text(t.shops.manage),
        ),
        // Owner: Delete. Member: Leave. Never both.
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
