import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/auth/application/auth/auth_providers.dart';
import 'package:freshcart_flutter/features/lists/application/last_opened_list/last_opened_list_controller.dart';
import 'package:freshcart_flutter/features/lists/application/list/list_providers.dart';
import 'package:freshcart_flutter/features/lists/application/lists/lists_controller.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'lists_drawer_controller.g.dart';

/// The view model behind `ListsDrawer`: one ready-to-draw row per list, and
/// remembering which one gets opened.
///
/// Null until the lists load. A failure is null too -- not worth its own
/// screen tier here: the drawer falls back to "nothing to switch to", and
/// the list already open keeps working regardless.
@riverpod
class ListsDrawerController extends _$ListsDrawerController {
  @override
  List<ListsDrawerRow>? build() {
    final lists = ref.watch(listsControllerProvider).dataOrNull;
    if (lists == null) return null;

    // Missing while loading or failed: rows show their member count instead
    // for that frame/load, rather than blocking the drawer on it.
    final summaries =
        ref.watch(listSummariesProvider).value ?? const <ListId, ListSummary>{};
    // Null for the one frame before identity resolves: everyone is shown
    // rather than blocking the drawer on it.
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

  /// Item counts ("6 left" / "All done"); null until they load.
  final ListSummary? summary;

  /// Everyone on [list] except the viewer -- "the avatars of who else is in
  /// them" (the design's own words).
  final List<ListMember> othersInList;
}
