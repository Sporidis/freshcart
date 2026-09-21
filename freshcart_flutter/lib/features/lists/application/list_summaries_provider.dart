import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/async/async_outcome.dart';
import 'package:freshcart_flutter/features/lists/application/lists_controller.dart';
import 'package:freshcart_flutter/features/lists/data/list_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'list_summaries_provider.g.dart';

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
