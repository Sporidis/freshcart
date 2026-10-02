import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/auth/application/auth/auth_providers.dart';
import 'package:freshcart_flutter/features/lists/application/last_opened_list/last_opened_list_controller.dart';
import 'package:freshcart_flutter/features/lists/application/lists/lists_controller.dart';
import 'package:freshcart_flutter/features/lists/data/repositories/list_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'list_providers.g.dart';

/// The signed-in user's member entry in [list], or null until we know who
/// the user is.
@riverpod
ListMember? myMembership(Ref ref, ShoppingList list) {
  final me = ref.watch(signedInUserIdProvider);
  return me == null ? null : list.memberFor(me);
}

/// Whether the signed-in user owns [list].
///
/// False until we know who the user is. That way "Leave" is shown in the
/// meantime, never "Delete for everyone".
@riverpod
bool isListOwner(Ref ref, ShoppingList list) {
  final me = ref.watch(signedInUserIdProvider);
  return me != null && list.isOwnedBy(me);
}

/// Item counts for each of the user's lists, for the drawer's "6 left" /
/// "All done".
///
/// Fetched in one request for all lists, instead of one request per list.
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
    // If it fails, the drawer just shows rows without counts. Not worth an
    // error screen.
    Err<List<ListSummary>>() => const {},
  };
}

/// One list, live. Updates by itself when someone renames it or joins.
///
/// Uses [ListRepository.watch] (a stream), not a one-time fetch.
/// See decisions.md #36.
@riverpod
Stream<Result<ShoppingList>> listById(Ref ref, ListId listId) =>
    ref.watch(listRepositoryProvider).watch(listId);

/// Which list `/lists` should open, or null to stay on `/lists` (still
/// loading, or the user has no lists).
///
/// Opens the last opened list, but only if the user is still on it. If
/// they left or deleted it, going there would show an error screen, whose
/// exit leads back here, in a loop.
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
