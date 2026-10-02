import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/auth/application/auth/auth_providers.dart';
import 'package:freshcart_flutter/features/lists/application/last_opened_list/last_opened_list_controller.dart';
import 'package:freshcart_flutter/features/lists/application/list/list_providers.dart';
import 'package:freshcart_flutter/features/lists/application/lists/lists_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lists_drawer_controller.g.dart';

/// The controller for `ListsDrawer`: one row per list, and remembering
/// which list was opened.
///
/// Null while loading, and also if loading failed. Then the drawer just
/// shows no lists. The open list keeps working.
@riverpod
class ListsDrawerController extends _$ListsDrawerController {
  @override
  List<ListsDrawerRow>? build() {
    final lists = ref.watch(listsControllerProvider).dataOrNull;
    if (lists == null) return null;

    // Item counts. If not loaded (or failed), rows show the member count
    // instead.
    final summaries =
        ref.watch(listSummariesProvider).value ?? const <ListId, ListSummary>{};
    // Null until we know who the user is. Until then, everyone's avatar is
    // shown (including yours).
    final me = ref.watch(signedInUserIdProvider);

    return [
      for (final list in lists)
        ListsDrawerRow(
          list: list,
          summary: summaries[list.id],
          othersInList: [
            for (final member in list.members)
              if (member.userId != me) member,
          ],
        ),
    ];
  }

  /// Remembers [id] as the list to reopen next time.
  Future<void> openList(ListId id) =>
      ref.read(lastOpenedListControllerProvider.notifier).select(id);
}

/// One row of the drawer.
class ListsDrawerRow {
  const ListsDrawerRow({
    required this.list,
    required this.summary,
    required this.othersInList,
  });

  final ShoppingList list;

  /// Item counts ("6 left" / "All done"), or null until loaded.
  final ListSummary? summary;

  /// Everyone on [list] except you. Shown as avatars.
  final List<ListMember> othersInList;
}
