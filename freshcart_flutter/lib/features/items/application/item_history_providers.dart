import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/items/data/repositories/item_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'item_history_providers.g.dart';

/// Product name suggestions for [listId] matching [query], most recently
/// used first -- what [QuickAddBar]'s chip row reads from (§09, decisions
/// #64).
///
/// autoDispose (the default for a plain function provider): each keystroke
/// makes this a new `(listId, query)` key, and nothing needs yesterday's
/// query's result sitting in the cache once nothing is watching it any more.
/// [QuickAddBar] debounces before it ever watches this, so the query here is
/// already settled, not fired on every keystroke.
@riverpod
Future<List<String>> itemSuggestions(
  Ref ref, {
  required ListId listId,
  required String query,
}) async {
  // Mirrors the server's own floor (ItemService.suggestNames) -- matching
  // one character would surface most of a list's history at once, which is
  // noise, not a suggestion. Checked here too so a too-short query never
  // even reaches the network.
  if (query.trim().length < 2) return const [];
  final result = await ref
      .watch(itemRepositoryProvider)
      .suggestNames(
        listId,
        query,
      );
  return switch (result) {
    Ok<List<String>>(:final value) => value,
    // A failed fetch just means no chips this keystroke, not an error worth
    // interrupting typing over -- there is nothing here for a retry to do
    // that typing the next character does not already redo.
    Err<List<String>>() => const [],
  };
}

/// Every distinct product name [listId] has had before, most recently used
/// first -- "Recently bought" (§06). [itemSuggestionsProvider]'s sibling:
/// that one filters by a typed query with a two-character floor, this one is
/// an unfiltered browse.
@riverpod
Future<List<NameHistoryEntry>> recentNames(Ref ref, ListId listId) async {
  final result = await ref.watch(itemRepositoryProvider).recentNames(listId);
  return switch (result) {
    Ok<List<NameHistoryEntry>>(:final value) => value,
    // Nothing to browse this load; a retry (reopening the screen) redoes the
    // same fetch, so there is no separate error state worth building here.
    Err<List<NameHistoryEntry>>() => const [],
  };
}
