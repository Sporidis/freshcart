import 'package:freshcart_domain/freshcart_domain.dart';
import 'package:freshcart_flutter/features/items/data/item_repository_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recent_names_provider.g.dart';

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
