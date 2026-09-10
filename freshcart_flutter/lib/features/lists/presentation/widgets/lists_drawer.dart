import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/core/l10n/locale_provider.dart';
import 'package:freshcart_flutter/core/router/app_router.dart';
import 'package:freshcart_flutter/features/lists/application/lists_controller.dart';
import 'package:go_router/go_router.dart';

// No @Preview here: this widget's only content comes from
// listsControllerProvider, which reaches the real ListRepository.
// previewApp deliberately takes no overrides (see preview_harness.dart), so
// showing this with real-looking data needs an in-memory fake living in
// lib/ — the same gap already noted for screen-level previews, not
// something to improvise as a side effect of this change.

/// Switches between the user's lists without a trip back to the Lists screen.
///
/// Deliberately just a switcher: creating and joining lists already have a
/// home on [ListsScreen][], and duplicating that flow here would be a second
/// place to keep in sync for no reader benefit — "All lists" at the bottom is
/// the door back to it.
class ListsDrawer extends ConsumerWidget {
  /// Creates the drawer, highlighting [currentListId] among the others.
  const ListsDrawer({required this.currentListId, super.key});

  /// The list already open, so it reads as the current one rather than a
  /// plain entry to tap.
  final ListId currentListId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final t = ref.watch(translationsProvider);
    final lists = ref.watch(listsControllerProvider);

    void openList(ListId id) {
      Navigator.of(context).pop();
      if (id != currentListId) context.go(Routes.listDetail(id));
    }

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(t.lists.title, style: theme.textTheme.headlineSmall),
            ),
            Expanded(
              child: switch (lists) {
                AsyncOutcome<List<ShoppingList>>(
                  value: Ok<List<ShoppingList>>(:final value),
                ) =>
                  ListView(
                    children: [
                      for (final list in value)
                        ListTile(
                          leading: Icon(
                            list.id == currentListId
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: list.id == currentListId
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline,
                          ),
                          title: Text(list.name),
                          subtitle: Text(
                            t.lists.memberCount(n: list.members.length),
                          ),
                          selected: list.id == currentListId,
                          onTap: () => openList(list.id),
                        ),
                    ],
                  ),
                // A load failure here is not worth its own screen tier — the
                // drawer just falls back to "nothing to switch to", and the
                // list already open keeps working regardless.
                _ => const SizedBox.shrink(),
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: Text(t.lists.allLists),
              onTap: () {
                Navigator.of(context).pop();
                context.go(Routes.lists);
              },
            ),
          ],
        ),
      ),
    );
  }
}
