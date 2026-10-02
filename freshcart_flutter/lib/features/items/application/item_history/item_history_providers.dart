import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/core/clock/clock_provider.dart';
import 'package:freshcart_flutter/features/items/application/item_history/recency_buckets.dart';
import 'package:freshcart_flutter/features/items/data/repositories/item_repository_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'item_history_providers.g.dart';

/// Item name suggestions for [listId] that match [query], most recent
/// first. Shown as chips above the add field (decisions.md #64).
///
/// Auto-disposed: old queries aren't kept in memory. [QuickAddBar] waits
/// until typing pauses before asking, so this isn't called on every key.
@riverpod
Future<List<String>> itemSuggestions(
  Ref ref, {
  required ListId listId,
  required String query,
}) async {
  // At least 2 letters, same as the server. One letter would match almost
  // everything. Checked here too, so we don't even send the request.
  if (query.trim().length < 2) return const [];
  final result = await ref
      .watch(itemRepositoryProvider)
      .suggestNames(
        listId,
        query,
      );
  return switch (result) {
    Ok<List<String>>(:final value) => value,
    // If it fails, just show no chips. Typing the next letter tries again
    // anyway.
    Err<List<String>>() => const [],
  };
}

/// Every item name list [listId] ever had, most recent first. For "Recently
/// bought" in search. Like [itemSuggestionsProvider], but without a search
/// query.
@riverpod
Future<List<NameHistoryEntry>> recentNames(Ref ref, ListId listId) async {
  final result = await ref.watch(itemRepositoryProvider).recentNames(listId);
  return switch (result) {
    Ok<List<NameHistoryEntry>>(:final value) => value,
    // If it fails, show nothing. Reopening search tries again.
    Err<List<NameHistoryEntry>>() => const [],
  };
}

/// [recentNamesProvider], split into "This week" / "Last week" / "Earlier".
/// Used by `SearchRecentlyBought`. All groups are empty while loading.
@riverpod
RecencyBuckets recentlyBought(Ref ref, ListId listId) => bucketByRecency(
  ref.watch(recentNamesProvider(listId)).value ?? const <NameHistoryEntry>[],
  ref.watch(clockProvider)(),
);
