import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/auth/application/auth/auth_providers.dart';
import 'package:freshcart_flutter/features/lists/application/last_opened_list/last_opened_list_controller.dart';
import 'package:freshcart_flutter/features/lists/application/lists/lists_controller.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/list_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'list_providers.g.dart';

/// The signed-in user's own membership of [list], or null until the
/// identity resolves.
@riverpod
ListMember? myMembership(Ref ref, ShoppingList list) {
  final me = ref.watch(signedInUserIdProvider);
  return me == null ? null : list.memberFor(me);
}

/// Whether the signed-in user owns [list].
///
/// False until the identity resolves: assuming membership rather than
/// ownership means the reversible action (leave) is what gets offered in
/// the meantime, never the destructive one (delete for everyone).
@riverpod
bool isListOwner(Ref ref, ShoppingList list) {
  final me = ref.watch(signedInUserIdProvider);
  return me != null && list.isOwnedBy(me);
}

/// Item counts for every list [listsControllerProvider] currently holds,
/// keyed by [ListId] -- the drawer's "6 left" / "All done" row (Flow 10,
/// §4). One batched call rather than a summary per row: fetching one list's
/// counts at a time would mean N requests for N lists open in the drawer at
/// once.
@riverpod
Future<Map<ListId, ListSummary>> listSummaries(Ref ref) async {
  final loaded = ref.watch(listsControllerProvider).dataOrNull;
  if (loaded == null || loaded.isEmpty) return const {};

  final result = await ref
      .watch(
        listRepositoryProvider,
      )
      .summaries([for (final list in loaded) list.id]);
  return switch (result) {
    Ok<List<ListSummary>>(:final value) => {
      for (final summary in value) summary.listId: summary,
    },
    // A failed fetch just means the drawer's rows show without their count
    // this load, not an error worth its own screen tier -- switching lists
    // still works regardless.
    Err<List<ListSummary>>() => const {},
  };
}

/// Live view of one list, for the detail screen and the router's membership
/// guard.
///
/// Backed by [ListRepository.watch] rather than a one-shot [ListRepository.byId]
/// call, so a rename or a collaborator joining while this screen is open
/// updates without a manual refresh (closes the gap `docs/decisions.md` #36
/// named). No optimistic overlay is needed here the way [ItemsController] needs
/// one: this screen has no local mutations of its own yet — rename and leave
/// exist on the port but nothing in the UI calls them. Add the same overlay
/// pattern if that changes.
@riverpod
Stream<Result<ShoppingList>> listById(Ref ref, ListId listId) =>
    ref.watch(listRepositoryProvider).watch(listId);

/// Where `/lists` should send a signed-in user, or null to stay put -- still
/// loading, or genuinely no lists (the empty state).
///
/// The last opened list wins only while it is still one of the user's
/// lists: after leaving or deleting it, the stored id points at a list the
/// server will refuse, and following it would land on the error screen,
/// whose exit leads straight back here.
@riverpod
ListId? listsLandingTarget(Ref ref) {
  final lists = ref.watch(listsControllerProvider);
  final lastOpened = ref.watch(lastOpenedListControllerProvider);
  if (lists.isLoading || lastOpened.isLoading) return null;

  final mine = lists.dataOrNull;
  if (mine == null || mine.isEmpty) return null;

  final last = lastOpened.value;
  return mine.any((l) => l.id == last) ? last : mine.first.id;
}
